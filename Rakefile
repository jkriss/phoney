namespace :tunnel do
 
  desc "Start SSH tunnel to remote host"
  task :start do
    SSH_TUNNEL = YAML.load_file("./config/tunnel.yml")
 
    public_host_username = SSH_TUNNEL['public_host_username']
    public_host          = SSH_TUNNEL['public_host']
    public_port          = SSH_TUNNEL['public_port']
    local_port           = SSH_TUNNEL['local_port']
 
    puts "Starting tunnel #{public_host}:#{public_port} to 127.0.0.1:#{local_port}"
    system "ssh -nNT -g -R *:#{public_port}:0.0.0.0:#{local_port} #{public_host_username}@#{public_host}"
    # system "ssh -v -N -p 22 -c 3des #{public_host_username}@#{public_host} -R #{public_port}:127.0.0.1:#{local_port}"
  end
 
end