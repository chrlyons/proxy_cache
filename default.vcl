vcl 4.0;

backend default {
    .host = "origin";
    .port = "8000";
}

sub vcl_hash {
    # Only hash based on URL, ignore all other factors
    hash_data(req.url);
    return (lookup);
}

sub vcl_recv {
    # Force lookup regardless of request type
    if (req.method == "GET" || req.method == "HEAD") {
        # Remove absolutely everything that could affect caching
        unset req.http.Cache-Control;
        unset req.http.Pragma;
        unset req.http.Cookie;
        unset req.http.Etag;
        unset req.http.If-None-Match;
        unset req.http.If-Modified-Since;
        unset req.http.X-Forwarded-For;
        unset req.http.User-Agent;
        unset req.http.Accept;
        unset req.http.Accept-Encoding;
        unset req.http.Accept-Language;
        unset req.http.Upgrade-Insecure-Requests;

        return(hash);
    }
    return(pass);
}

sub vcl_backend_response {
    if (beresp.status == 200) {
        set beresp.ttl = 60s;
        set beresp.grace = 1h;  # Allow serving stale content

        # Remove all backend response headers that could prevent caching
        unset beresp.http.Cache-Control;
        unset beresp.http.Pragma;
        unset beresp.http.Etag;
        unset beresp.http.Set-Cookie;
        unset beresp.http.Vary;
        unset beresp.http.Expires;
        unset beresp.http.Last-Modified;

        # Force the object to be cacheable
        set beresp.uncacheable = false;
    }
    return(deliver);
}

sub vcl_deliver {
    # Always set cache-control headers in response
    set resp.http.Cache-Control = "public, max-age=60";

    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }

    # Add detailed debug headers
    set resp.http.X-Cache-Hits = obj.hits;
    set resp.http.X-Varnish-TTL = obj.ttl;
    set resp.http.X-Served-By = "Varnish";

    return(deliver);
}