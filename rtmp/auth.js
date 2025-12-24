const http = require('http');
const querystring = require('querystring');

const server = http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/auth') {
    let body = '';

    req.on('data', (chunk) => {
      body += chunk;
    });

    req.on('end', () => {
      console.log("heelo");
      const params = querystring.parse(body);
      const key = params.key;
      if (key === 'KEY') {
        res.writeHead(200);
        res.end();
      } else {
        res.writeHead(403);
        res.end();
      }
    });
  } else {
    res.writeHead(404);
    res.end();
  }
});

server.listen(8000, () => {
  console.log('Server running on port 8000');
});