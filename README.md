# MikroTik RouterOS Script: Update Cloudflare DNS with Public IP

## Overview

This script is designed to automatically update a Cloudflare DNS A record with your MikroTik router's public IP address. kinda like a dynamic DNS (but without needing for software or any third party) If your ISP assigns a dynamic IP, this script ensures that your Cloudflare DNS record always points to the correct address.

## IMPORTANT WARNING

🚨 **THIS SCRIPT ONLY WORKS IF YOU HAVE A DYNAMIC PUBLIC IP.** 🚨&#x20;

(e.g., 203.0.113.45)

⚠️ **IF YOUR ISP USES CG-NAT (CARRIER-GRADE NAT), THIS SCRIPT WILL NOT WORK.** ⚠️

(e.g., 100.88.146.146)\
Your router will have a private IP rather than a public-facing IP, meaning it cannot update Cloudflare with a correct external address.

## Features

- Retrieves the public IP from any interface.

- Updates the Cloudflare DNS A with Cloudflare's API record only when a change is detected.

- Can be scheduled to run at any intervals via MikroTik's scheduler.

## Example

### Scenario:

You have a MikroTik router with a dynamic IP assigned by your ISP on Eth1 . Your own domain `example.com` is managed via Cloudflare, and you want your router to automatically update the Cloudflare DNS A record whenever your IP changes (either by power on/off or ISP or any other reason).

### Expected Behavior:

1. Your ISP assigns or you on/off toggle the router/connection and get a new IP (e.g., `203.0.23.45`).
2. The script detects the change and updates Cloudflare's DNS record.
3. Your domain `example.com` now correctly resolves to `203.0.23.45`.

## Prerequisites

Before running this script, make sure you have:

1. A MikroTik router running RouterOS preferably with full access (not sure if scrip would work fully with write access )
2. A Cloudflare account with API token permissions for updating DNS records. (explanation below)
3. A (paid or free) DNS record in your Cloudflare that you want to update dynamically.

## Setup Instructions **( skip to 3 if you already have the zoneId , recordId and apiToken  )**

### 1. Get Your Cloudflare API Token

1. Log in to your Cloudflare account.
2. Go to **My Profile > API Tokens**.
3. Click **Create Token**.
4. Use the **Edit zone DNS** template.
5. Select the specific zone (domain) you want to update.
6. Generate and copy the API token.

### 2. Find Your Cloudflare Zone ID and Record ID

1. Go to **Cloudflare Dashboard**.
2. Select the domain you want to update.
3. Under **API**, note down your **Zone ID**.
4. Go to **DNS** settings.
5. Locate the A record you want to update.
6. Use Cloudflare’s API to get the Record ID:
   ```sh
   #!/bin/bash
   # This bash script can help you get the record id

   # Cloudflare credentials
   ZONE_ID="REPLACE_WITH_YOUR_ZONE_ID"
   EMAIL="YOUR_CLOUDFLARE_EMAIL"
   API_KEY="API_KEY"

   # record you wanna look for
   RECORD_NAME="XXX.example.com"



   # Get DNS record
   RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
        -H "X-Auth-Email: $EMAIL" \
        -H "X-Auth-Key: $API_KEY" \
        -H "Content-Type: application/json")

   # Parse the response to get the record ID
   RECORD_ID=$(echo $RESPONSE | jq -r '.result[0].id')

   echo $RECORD_ID

   ```
   \


   save the `id` value of the record you wanna update.

### 3. Configure and Deploy the Script

1. Open Winbox or SSH into your MikroTik router (also you can use web or any other interface).

2. Navigate to **System > Scripts**.

3. Create a new script and paste the following code:**(just make sure you change the values)**

   ```routeros
   # RouterOS Script .rsc
   ###                            ###
   ### Replace with actual values ###
   ###                            ###
   :global intf "ether1"

   # ZoneID
   :global cfi "Your_zone_id"

   # RECORD_ID
   :global cfr "Your_rec_id"

   # ACCOUNT_EMAIL_ADDRESS
   :global cfe "xxxx@x.com"

   # API_KEY (Token)
   :global cfk "your_Token"

   # DOMAIN
   :global cfd "XXX.example.com"
   ###                            ###
   ### Replace with actual values ###
   ###                            ###



   # getting Pub_IP from ip/address 
   :put [:pick [/ip/address/get value-name=address number=[find interface=$intf]] 0 [:find [/ip/address/get value-name=address number=[find interface=$intf]] "/"]]
   :global cfip [resolve $cfd];
   :if ($cfip != $myip) do={
       :global url "https://api.cloudflare.com/client/v4/zones/$cfi/dns_records/$cfr";
       :global header "content-type:application/json,X-Auth-Email:$cfe,X-Auth-Key:$cfk";
       :global data "{\"type\":\"A\",\"name\":\"$cfd\",\"content\":\"$myip\",\"ttl\":120}";
       :log warning "[Cloudflare DDNS] WAN IPv4 address for interface $cfip has been changed to $myip.";
       :log warning "[Cloudflare DDNS] Updating Domain Record ...";
       :local jsonAnswer [/tool fetch mode=https http-method=put http-header-field=$header http-data=$data url=$url as-value output=file]
       :log warning $jsonAnswer
   }    
   ```



1. Save the script with a meaningful name, such as **Cloud-Flare-DNS-Updater**.\
   or you can simply copy and paste this one command code that creates the script in system script for you just make sure you change the values :

   ```
   /system script add dont-require-permissions=no name=Cloud-Flare-DNS-Updater   source="# RouterOS Script .rsc\
       \n###                            ###\
       \n### Replace with actual values ###\
       \n###                            ###\
       \n:global intf \"ether1\"\
       \n\
       \n# ZoneID\
       \n:global cfi \"Your_zone_id\"\
       \n\
       \n# RECORD_ID\
       \n:global cfr \"Your_rec_id\"\
       \n\
       \n# ACCOUNT_EMAIL_ADDRESS\
       \n:global cfe \"xxxx@x.com\"\
       \n\
       \n# API_KEY (Token)\
       \n:global cfk \"your_Token\"\
       \n\
       \n# DOMAIN\
       \n:global cfd \"XXX.example.com\"\
       \n###                            ###\
       \n### Replace with actual values ###\
       \n###                            ###\
       \n\
       \n\
       \n\
       \n# getting Pub_IP from ip/address \
       \n:put [:pick [/ip/address/get value-name=address number=[find interface=\$intf]] 0 [:find [/ip/address/get value-name=address number=[find interface=\$intf]] \"/\"]]\
       \n:global cfip [resolve \$cfd];\
       \n:if (\$cfip != \$myip) do={\
       \n    :global url \"https://api.cloudflare.com/client/v4/zones/\$cfi/dns_records/\$cfr\";\
       \n    :global header \"content-type:application/json,X-Auth-Email:\$cfe,X-Auth-Key:\$cfk\";\
       \n    :global data \"{\\\"type\\\":\\\"A\\\",\\\"name\\\":\\\"\$cfd\\\",\\\"content\\\":\\\"\$myip\\\",\\\"ttl\\\":120}\";\
       \n    :log warning \"[Cloudflare DDNS] WAN IPv4 address for interface \$cfip has been changed to \$myip.\";\
       \n    :log warning \"[Cloudflare DDNS] Updating Domain Record ...\";\
       \n    :local jsonAnswer [/tool fetch mode=https http-method=put http-header-field=\$header http-data=\$data url=\$url as-value output=file]\
       \n    :log warning \$jsonAnswer\
       \n}    
   ```

This is now saved in the system/scripts to run the script periodically :



1. example of scheduler with an interval (e.g., every 5 minutes).
   ```
   /system scheduler add interval=5m name="CloudFlare DDNS" on-event="/system script run Cloud-Flare-DNS-Updater;"
   ```



## Testing & Troubleshooting

- **Make sure you have at least one working DNS server on your router by checking /ip/dns (obviously you need it for domain resolution)**
- `#if not use the following :`
- `/ip dns set servers=1.1.1.1,1.0.0.1,9.9.9.9`
- **Test manually** by running the script from **System > Scripts**.&#x20;
- `/system script run Cloud-Flare-DNS-Updater;`
- **Check logs** under **Log** to debug issues.
- `log/print`
- **Confirm updates** by checking Cloudflare's DNS settings. or resolve it via command .
- `:put [resolve "XXX.example.com"]`
- **Use API responses** to verify if the request is successful.

## Notes

- sometimes it might take a while for new ip to be replaced by old one and the domain might resolve to the old ip (depending on you setup , dns , isp dns cache ... )
- Ensure your Cloudflare API token has the right permissions.
- Some ISPs provide a private IP instead of a public IP—verify with `whatismyip`.
- If your IP changes frequently, run the script more often.

## License

Feel free to use and modify this script for your use case. If you have any suggestion or improvment, consider contributing back!

---

Let me know if you need any adjustments!

