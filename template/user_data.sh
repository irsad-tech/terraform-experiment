#!/bin/bash
#echo "<h1>Hello, World</h1>" > index.html
cat <<- EOF > index.html
<!DOCTYPE html>
<head>
	<title>Terraform Built This!</title>
</head>
<body>
	<p>Static web page in a single server is up and running.</p></container>
</body>
</html>

EOF

nohup busybox httpd -f -p 80 &
