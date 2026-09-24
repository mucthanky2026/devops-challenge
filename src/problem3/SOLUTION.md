## Situation
Docker compose with Redis , postgres and a simple API is running on a single host.

Verify root folder:
```
curl -v localhost:8080

* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
> GET / HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< Server: nginx/1.25.5
< Date: Wed, 23 Sep 2026 09:47:48 GMT
< Content-Type: application/octet-stream
< Content-Length: 24
< Connection: keep-alive
< 
Welcome to the platform
* Connection #0 to host localhost left intact
```

Call to API endpoint `/status` returns 404 error:
```
curl -v localhost:8080/status
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
> GET /status HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 404 Not Found
< Server: nginx/1.25.5
< Date: Wed, 23 Sep 2026 09:47:51 GMT
< Content-Type: text/html
< Content-Length: 153
< Connection: keep-alive
< 
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx/1.25.5</center>
</body>
</html>
* Connection #0 to host localhost left intact.
```
Test  API `/api/users` endpoint returns 404 error:
```curl -v localhost:8080/api/users
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
> GET /api/users HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 502 Bad Gateway
< Server: nginx/1.25.5
< Date: Wed, 23 Sep 2026 10:03:27 GMT
< Content-Type: text/html
< Content-Length: 157
< Connection: keep-alive
< 
<html>
<head><title>502 Bad Gateway</title></head>
<body>
<center><h1>502 Bad Gateway</h1></center>
<hr><center>nginx/1.25.5</center>
</body>
</html>
* Connection #0 to host localhost left intact
```

Log when starting the API container shows that the API is listening on port 3000:
```
ginx-1     | 2026/09/23 09:47:30 [notice] 1#1: start worker process 33
nginx-1     | 2026/09/23 09:47:30 [notice] 1#1: start worker process 34
nginx-1     | 2026/09/23 09:47:30 [notice] 1#1: start worker process 35
api-1       | API running on 3000
```

## Fix
1. From first test commond with `curl -v localhost:8080` we can see that the nginx is running and listening on port 8080. That mean the nginx is working fine and the problem is with the API and nginx configuration.
2. Check ngin configuration file `./api/nginx/conf.d/default.conf` and see that the nginx is forwarding requests to port 3001 while API is listening on port 3000. 

Update nginx configuration `./api/nginx/conf.d/default.conf` to forward requests to port 3000 instead of 3001.
```./api/nginx/conf.d/default.conf
server {
    listen 80;

    location = / {
        return 200 "Welcome to the platform\n";
    }

    location /api/ {
        proxy_pass http://api:3000;
    }

}
```

Secondly, the `/status` API will not work call because the nginx configuration is forwarding requests to `/api/` path. So we nees to update the nginx configuration to forward `/status` requests to the API as well.

```./api/nginx/conf.d/default.conf
    location /status {
        proxy_pass http://api:3000;
    }
```

3. Restart the nginx container to apply the changes. Verify:
Endpoint `/status` returns 200 OK:
```
curl -v localhost:8080/status

* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
> GET /status HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< Server: nginx/1.25.5
< Date: Wed, 23 Sep 2026 10:07:50 GMT
< Content-Type: application/json; charset=utf-8
< Content-Length: 15
< Connection: keep-alive
< X-Powered-By: Express
< ETag: W/"f-VaSQ4oDUiZblZNAEkkN+sX+q3Sg"
< 
* Connection #0 to host localhost left intact
{"status":"ok"}
```

Endpoint `/api/users` returns 200 OK:
```
curl -v localhost:8080/api/users
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
> GET /api/users HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< Server: nginx/1.25.5
< Date: Wed, 23 Sep 2026 10:07:45 GMT
< Content-Type: application/json; charset=utf-8
< Content-Length: 53
< Connection: keep-alive
< X-Powered-By: Express
< ETag: W/"35-106zXsnAR8+2ie56ui/MOEXiGbg"
< 
* Connection #0 to host localhost left intact
{"ok":true,"time":{"now":"2026-09-23T10:07:45.680Z"}}
```

## Root cause and solution
The root cause of the issue was that the nginx configuration was forwarding requests to the wrong port (3001) while the API was listening on port 3000. Additionally, the `/status` endpoint was not configured in nginx, resulting in a 404 error. The solution involved updating the nginx configuration to forward requests to the correct port (3000) and adding a location block for the `/status` endpoint. After making these changes and restarting the nginx container, both endpoints returned the expected responses.

1. Use dynamic nginx configuration: use variables for API port and name in the nginx configuration file. This allows for easier updates and changes to the API service without needing to modify the nginx configuration directly.

Update the nginx configuration file to use variables for the API name and port as template. For example, replace hardcoded values with `${API_NAME}` and `${API_PORT}`.

```nginx
server {
    listen ${NGINX_PORT};   
    location = / {
        return 200 "Welcome to the platform\n";
    }
    location /status {
        proxy_pass http://${API_NAME}:${API_PORT};
    }
    location /api/ {
        proxy_pass http://${API_NAME}:${API_PORT};
    }
}
```
Update the `.env` file to include the API name and port variables:
```
NGINX_PORT=80
API_PORT=3000
API_NAME=api
```

Update the docker-compose file to pass the environment variables to the nginx container:
```yaml
services:
  nginx:
    environment:
      - NGINX_PORT=${NGINX_PORT:-80}    
      - API_PORT=${API_PORT:-3000}
      - API_NAME=${API_NAME:-api}
    volumes:
      - ./nginx/template:/etc/nginx/templates
```

In this way, if the API service name or port changes in the future, you can simply update the `.env` file without needing to modify the nginx configuration directly. This makes the system more maintainable and flexible.

2. Update the API to listen on the port specified in the environment variable `API_PORT`. This allows for easier configuration and avoids hardcoding the port number in the code.

Update the API code to use the `API_PORT` environment variable when starting the server. For example, in the `index.js` file of the API service, change the listen statement to:
```javascript
app.listen(process.env.API_PORT || 3000, () => console.log(`API running on ${process.env.API_PORT || 3000}`));
```

3. Seperate `.env` file per environment