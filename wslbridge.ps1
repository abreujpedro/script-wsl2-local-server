
$remoteport = wsl -d Ubuntu -e sh -c "ip addr show eth0 | grep 'inet\b' | awk '{print $2}' | cut -d/ -f1";
$found = $remoteport -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

if( $found ){
  $remoteport = $matches[0];
} else{
  echo "The Script Exited, the ip address of WSL 2 cannot be found";
  exit;
}

echo "WSL ip address $remoteport";

#[Ports]

#All the ports you want to forward separated by coma
$ports=@(3500);


#[Static ip]
#You can change the addr to your ip config to listen to a specific address
$addr='0.0.0.0';
$ports_a = $ports -join ",";


#Remove Firewall Exception Rules
iex "Remove-NetFireWallRule -DisplayName 'WSL Firewall Unlock' ";

#adding Exception Rules for inbound and outbound Rules
echo "Firewall inbound/outbound rules";
iex "New-NetFireWallRule -DisplayName 'WSL Firewall Unlock' -Direction Outbound -LocalPort $ports_a -Action Allow -Protocol TCP";
iex "New-NetFireWallRule -DisplayName 'WSL Firewall Unlock' -Direction Inbound -LocalPort $ports_a -Action Allow -Protocol TCP";

for( $i = 0; $i -lt $ports.length; $i++ ){
  $port = $ports[$i];
  echo "portproxy ${addr}:${port} to ${remoteport}:${port}";
  iex "netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$addr";
  iex "netsh interface portproxy add v4tov4 listenport=$port listenaddress=$addr connectport=$port connectaddress=$remoteport";
}

echo "PRIVATE IPV4 :" (
    Get-NetIPConfiguration |
    Where-Object {
        $_.IPv4DefaultGateway -ne $null -and
        $_.NetAdapter.Status -ne "Disconnected"
    }
).IPv4Address.IPAddress


