# Docker Caching Demo Environment

This project demonstrates a multi-tier proxy and caching setup using Docker Compose, featuring:
- Python HTTP Server (Origin)
- Varnish Cache (CDN simulation)
- Nginx (Reverse Proxy)

## Architecture

```
Client -> Nginx (80) -> Varnish Cache -> Python Origin (8080)
```

## Components

### 1. Origin Server
- Simple Python HTTP server
- Serves static content from `origin_content/`
- Internal service on port 8080
- Uses Python's built-in HTTP server

### 2. Varnish Cache
- Simulates a CDN-like caching layer
- Acts as a reverse proxy and HTTP accelerator
- Caches responses for 60 seconds
- Configurable via `default.vcl`
- Internal service
- Cache status indicated via X-Cache headers

### 3. Nginx Proxy
- Acts as the entry point for all requests
- Provides load balancing capabilities
- Adds request/response headers
- Handles error pages
- Exposes health check endpoint
- Public-facing on port 80

## Setup & Usage

1. Start the environment:
```bash
docker compose up -d
```

2. Access the services:
- Main application (through Nginx): http://localhost
- Direct to origin: http://localhost:8080
- Health check: http://localhost/health

3. Test caching:
```bash
# First request (should show MISS)
curl -I http://localhost

# Second request (should show HIT)
curl -I http://localhost

# Health check
curl http://localhost/health
```

4. Observe headers:
- `X-Cache`: Shows HIT or MISS
- `X-Cache-Hits`: Number of cache hits
- `X-Proxy-Path`: Shows request path through services
- The web interface also displays these headers in real-time

## Configuration

### Nginx Configuration (`nginx.conf`)
```nginx
location / {
    proxy_pass http://cache:80;
    # Headers for proxying
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    add_header X-Proxy-Path "Nginx -> Varnish -> Origin" always;
}
```

### Varnish Cache Configuration (`default.vcl`)
```vcl
# TTL for cached content
set beresp.ttl = 60s;

# Cache status headers
set resp.http.X-Cache = "HIT/MISS";
set resp.http.X-Cache-Hits = obj.hits;
```

## Maintenance

### Clearing the Cache
```bash
# Remove and recreate cache container
docker compose stop cache
docker compose rm -f cache
docker compose up -d cache
```

### Viewing Logs
```bash
# All services
docker compose logs

# Specific service
docker compose logs proxy
docker compose logs cache
docker compose logs origin
```

## Development

### Modifying Origin Content
1. Edit files in `origin_content/`
2. Changes are immediate (volume mounted)

### Updating Configurations
1. Edit `nginx.conf` or `default.vcl`
2. Restart the respective service:
```bash
# For Nginx changes
docker-compose restart proxy

# For Varnish changes
docker-compose restart cache
```

## Troubleshooting

### Request Flow Issues
1. Test each layer:
```bash
# Test origin directly
curl -I http://localhost:8080

# Test through Nginx
curl -I http://localhost
```

2. Check service logs:
```bash
# Check Nginx logs
docker-compose logs proxy

# Check Varnish logs
docker-compose logs cache
```

### Cache Not Working
- Verify all services are running: `docker-compose ps`
- Check for cache-busting headers in requests
- Verify TTL settings in Varnish configuration
- Check `X-Proxy-Path` header for correct routing

## Web Interface

The included UI provides:
- Real-time cache status display
- Complete response header information
- Cache hit counter
- Manual refresh button
- Visual status indicators

## Understanding the Flow

1. Request arrives at Nginx (port 80)
2. Nginx adds headers and forwards to Varnish
3. Varnish either:
   - Serves cached content (HIT)
   - Fetches from origin (MISS)
4. Response returns through the chain
5. Each layer adds its own headers