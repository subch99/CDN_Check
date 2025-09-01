#!/bin/bash

# Enhanced CDN Detection Script - Detects 50+ CDN providers
# Usage: ./cdn_detector.sh example.com

DOMAIN=$1
TIMEOUT=5
CURL_OPTS="-sI --max-time $TIMEOUT -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'"

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 example.com"
    exit 1
fi

echo "[🔍] Checking $DOMAIN for CDN use..."

# 1. DNS Lookup - Get all IPs
echo "[1] DNS Lookup:"
IPS=$(dig +short "$DOMAIN" | grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u)
if [ -z "$IPS" ]; then
    echo "    No IP found. Domain may not be resolvable."
    exit 1
fi

echo "$IPS" | while read IP; do
    echo "    $IP"
done

IP_COUNT=$(echo "$IPS" | wc -l)

# 2. Check IP Count (Anycast pattern)
if [ "$IP_COUNT" -gt 3 ]; then
    echo "    Multiple IPs detected. Likely using CDN (anycast)."
fi

# 3. Reverse DNS Check for all IPs
echo "[2] Reverse DNS Check:"
CDN_DETECTED=""
while read IP; do
    HOSTNAME=$(nslookup "$IP" 2>/dev/null | grep 'name =' | awk -F'= ' '{print $2}' | sed 's/\.$//')
    if [ -n "$HOSTNAME" ]; then
        echo "    $IP -> $HOSTNAME"
        
        # Check against 50+ CDN patterns
        if echo "$HOSTNAME" | grep -q -i -E \
            'cloudflare|cloudfront|akamai|fastly|azureedge|googleusercontent|incapdns|stackpath|cdn77|keycdn|bunnycdn|cdnify|awscloud|edgekey|edgesuite|netdna|maxcdn|cdn77|section.io|highwinds|mirror-image|limelight|cachefly|quantil|cdnetworks|cdngc|gccdn|anankacdn|aryaka|belugacdn|cdnsun|cedexis|reflected|swiftcdn|twist|zenedge|fastcdn|footprint|level3|leaseweb|cotendo|telefonica|chinacache|edgecast|att-dsa|alicloud|tencentcloud|huaweicloud|imperva|myqcloud|rackcdn|securerax|supersonic|turbobytes|yunjiasu'; then
            CDN_PROVIDER=$(echo "$HOSTNAME" | grep -oi -E \
            'cloudflare|cloudfront|akamai|fastly|azureedge|googleusercontent|incapdns|stackpath|cdn77|keycdn|bunnycdn|cdnify|awscloud|edgekey|edgesuite|netdna|maxcdn|cdn77|section.io|highwinds|mirror-image|limelight|cachefly|quantil|cdnetworks|cdngc|gccdn|anankacdn|aryaka|belugacdn|cdnsun|cedexis|reflected|swiftcdn|twist|zenedge|fastcdn|footprint|level3|leaseweb|cotendo|telefonica|chinacache|edgecast|att-dsa|alicloud|tencentcloud|huaweicloud|imperva|myqcloud|rackcdn|securerax|supersonic|turbobytes|yunjiasu' | head -1)
            echo "    ✅ CDN Detected: $CDN_PROVIDER"
            CDN_DETECTED="$CDN_PROVIDER"
        fi
    else
        echo "    $IP -> No reverse DNS"
    fi
done <<< "$IPS"

# 4. HTTP Header Check
echo "[3] HTTP Header Check:"
URLS=("https://$DOMAIN" "http://$DOMAIN")
for URL in "${URLS[@]}"; do
    if curl $CURL_OPTS "$URL" > /tmp/curl_headers 2>/dev/null; then
        break
    fi
done

# Check for CDN headers
HEADERS=$(cat /tmp/curl_headers)
if [ -n "$HEADERS" ]; then
    echo "    Headers retrieved:"
    echo "$HEADERS" | head -10
    
    # Check 50+ CDN header patterns
    CDN_HEADER=$(echo "$HEADERS" | grep -i -E \
        'server:.*cloudflare|cf-ray|server:.*akamai|x-akamai|server:.*fastly|fastly-ff|x-cache:.*cloudfront|x-amz-cf-pop|server:.*edgecast|x-ec|server:.*imperva|incap-sid|server:.*stackpath|sp-edge|server:.*keycdn|keycdn-origin|server:.*bunnycdn|bunnycdn|server:.*azureedge|x-azure|server:.*google|x-google|server:.*chinacache|cc-cloud|server:.*limelight|llnwd|server:.*cdn77|cdn77|server:.*leaseweb|lsw|server:.*yunjiasu|yunjiasu|server:.*tencent|q-cloud|server:.*alibaba|aliyun|server:.*huawei|hwcdn|server:.*cloudflare|cf-request-id|server:.*aws|amazon|server:.*maxcdn|maxcdn|server:.*netdna|netdna|server:.*cdnify|cdnify|server:.*section|section|server:.*highwinds|highwinds|server:.*cachefly|cachefly|server:.*quantil|quantil|server:.*cdnetworks|cdnetworks|server:.*aryaka|aryaka|server:.*belugacdn|belugacdn|server:.*cedexis|cedexis|server:.*reflect|reflect|server:.*swiftcdn|swiftcdn|server:.*turbobytes|turbobytes|server:.*zenedge|zenedge' | head -1)
    
    if [ -n "$CDN_HEADER" ]; then
        CDN_PROVIDER=$(echo "$CDN_HEADER" | grep -oi -E \
            'cloudflare|akamai|fastly|edgecast|imperva|stackpath|keycdn|bunnycdn|azureedge|google|chinacache|limelight|cdn77|leaseweb|yunjiasu|tencent|alibaba|huawei|aws|maxcdn|netdna|cdnify|section|highwinds|cachefly|quantil|cdnetworks|aryaka|belugacdn|cedexis|reflect|swiftcdn|turbobytes|zenedge' | head -1)
        echo "    ✅ CDN Detected via Headers: $CDN_PROVIDER"
        CDN_DETECTED="${CDN_DETECTED:-$CDN_PROVIDER}"
    fi
else
    echo "    Failed to retrieve headers"
fi

# 5. ASN Check (using whois)
echo "[4] ASN Check:"
FIRST_IP=$(echo "$IPS" | head -1)
if [ -n "$FIRST_IP" ]; then
    ASN_INFO=$(whois "$FIRST_IP" 2>/dev/null | grep -i -E \
        'cloudflare|akamai|fastly|amazon|google|microsoft|azure|edgecast|imperva|stackpath|leaseweb|limelight|cdn77|keycdn|bunny|incapsula|chinacache|tencent|alibaba|huawei|level3|highwinds|cachefly|quantil|cdnetworks|aryaka' | head -3)
    
    if [ -n "$ASN_INFO" ]; then
        echo "    ASN Information:"
        echo "$ASN_INFO" | while read line; do
            echo "    $line"
        done
        CDN_PROVIDER=$(echo "$ASN_INFO" | grep -oi -E \
            'cloudflare|akamai|fastly|amazon|google|microsoft|azure|edgecast|imperva|stackpath|leaseweb|limelight|cdn77|keycdn|bunny|incapsula|chinacache|tencent|alibaba|huawei|level3|highwinds|cachefly|quantil|cdnetworks|aryaka' | head -1)
        echo "    ✅ CDN Detected via ASN: $CDN_PROVIDER"
        CDN_DETECTED="${CDN_DETECTED:-$CDN_PROVIDER}"
    fi
fi

# 6. Final Conclusion
echo "[📊] Final Analysis:"
if [ -n "$CDN_DETECTED" ]; then
    echo "    ✅ Domain is protected by: $CDN_DETECTED"
    echo "    🛡️  CDN detected via: $(if [ -n "$CDN_DETECTED" ]; then echo "Multiple methods"; fi)"
else
    if [ "$IP_COUNT" -le 2 ]; then
        echo "    🚨 NO CDN DETECTED - Domain may be exposing ORIGIN IP"
        echo "    ⚠️  Recommendation: Implement CDN protection immediately"
    else
        echo "    🤔 Unknown CDN or custom infrastructure detected"
        echo "    🔍 Multiple IPs found but no known CDN patterns identified"
    fi
fi

# Cleanup
rm -f /tmp/curl_headers
