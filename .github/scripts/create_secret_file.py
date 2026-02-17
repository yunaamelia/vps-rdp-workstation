import os

password = os.environ.get("VPS_PASSWORD", "")
if password:
    with open("./secrets", "w") as f:
        f.write(f"password={password}\n")
    print("Secrets file created.")
else:
    print("VPS_PASSWORD not set, skipping secrets file creation.")
