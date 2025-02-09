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
