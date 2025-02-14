vcl 4.0;

backend default {
    .host = "origin";
    .port = "8000";
}

sub vcl_recv {
    # Only cache GET and HEAD requests
    if (req.method != "GET" && req.method != "HEAD") {
        return(pass);
    }

    # Check for explicit no-cache requests only if they include "no-cache"
    if (req.http.Cache-Control == "no-cache") {
        return(pass);
    }

    return(hash);
}

sub vcl_backend_response {
    if (beresp.status == 200) {
        set beresp.ttl = 60s;
        set beresp.uncacheable = false;
    }
    return(deliver);
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }

    # Add hit count
    set resp.http.X-Cache-Hits = obj.hits;

    return(deliver);
}