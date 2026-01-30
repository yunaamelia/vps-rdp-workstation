import paramiko
import os
import sys

hostname = "159.223.73.252"
username = "root"
password = "gg123123@"
key_file = os.path.expanduser("~/.ssh/id_ed25519.pub")

try:
    with open(key_file, "r") as f:
        public_key = f.read().strip()
except FileNotFoundError:
    print(f"Key file {key_file} not found")
    sys.exit(1)

print(f"Connecting to {hostname}...")
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    client.connect(hostname, username=username, password=password)
    print("Connected.")
    
    # Create .ssh directory
    stdin, stdout, stderr = client.exec_command("mkdir -p ~/.ssh && chmod 700 ~/.ssh")
    print(stdout.read().decode())
    
    # Add key
    cmd = f"echo '{public_key}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    stdin, stdout, stderr = client.exec_command(cmd)
    
    if stdout.channel.recv_exit_status() == 0:
        print("Key added successfully.")
    else:
        print("Error adding key:", stderr.read().decode())

finally:
    client.close()
