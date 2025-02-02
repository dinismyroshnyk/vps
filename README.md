# Setting Up NixOS on an Oracle Cloud Ampere Instance

This guide outlines the steps to set up NixOS on an Ampere instance in Oracle Cloud Infrastructure (OCI). The process begins with configuring an Oracle Linux instance and concludes with replacing it with NixOS using `nixos-anywhere`.

## Prerequisites

- An Oracle Cloud account.
- Access to a Unix/Unix-like machine or VM (virtual machine).
- An SSH key pair for authentication.

## Steps

### Step 1: Create an Ampere Instance in Oracle Cloud

- The process for creating an Ampere instance may change with time, so refer to the newest documentation.
- The script was tested on an instance with the following configuration:
    * Image: Oracle Linux 9
    * Shape: VM.Standard.A1.Flex
    * Number of OCPUs: 4
    * Ammount of Memory: 24 GB
    * Boot Volume Size: 200 GB
- The SSH key added to the instance is the pair to the SSH key that is further used/pointed at in the script.
- You should add your `public` key (`.pub` file) to the instance.
- This configuration should be in line with Oracle's free tier limitations.

### Step 2: Run the `initial_setup.sh` Script

- Clone this repository to your local machine/VM.
- Update the `ampere-config/configuration.nix` to match your needs. This file declares the state of the system after the initial setup is completed.
- Update the `ampere-install/configuration.nix` by adding your `public` SSH key (the same key that is added to the instance) to `users.users.root.openssh.authorizedKeys.keys`.
- Configure the script by changing the placeholders in the `Configurable variables` section:
    * `REMOTE_USER` - The username provided by Oracle after instance creation. If `Oracle Linux` is used, it should be `opc`.
    * `REMOTE_HOST` - The public IP of the instance. can be copied from the instance's GUI.
    * `SSH_KEY` - The path to your `private` SSH key.
- Make the bash script executable:

```bash
chmod +x initial_setup.sh
```

- Run the script:

```bash
./initial_setup.sh
```

**This script will attempt to:**
- Log into the instance as `REMOTE_USER`, using the provided `SSH_KEY`.
- Enable public key authentication on the remote instance to allow SSH connections without passing the SSH key explicitly.
- Check if `nix` is installed on the local machine/VM. If not, it will attempt to install it as it is needed for the next step.
- Install NixOS on the remote instance using `nixos-anywhere`.
- Update the system on the remote instance with a more, up-to-date configuration.

> [!CAUTION]
> If this part of the script fails, it will probably "brick" the instance. The current instance should be deleted and a new one should be created.

### Step 3: Verify NixOS Installation

- After the installation completes, you can SSH into the machine your user (the one that contains your key in `openssh.authorizedKeys.keys` option in `ampere-config/configuration.nix`).

``` bash
TERM=xterm-256color ssh <user>@<public_ip>
```

> [!NOTE]
> Change `<user>` and `<public_ip>` placeholders to match your username and the instance's public IP.


## References and Acknowledgements

- [NixOS Anywhere](https://github.com/nix-community/nixos-anywhere)
- [Disko](https://github.com/nix-community/disko)
- [Vimjoyer's youtube guide](https://www.youtube.com/watch?v=4sypfTBuEbA&t=197s)
- [Mic92's example repo](https://github.com/nix-community/nixos-anywhere-examples)
- [joegoldin's blog post](https://joegold.in/blog/posts/08-21-2024-nixos-dev-env/)
- [Moniruzzaman Shimul's Medium article](https://medium.com/@moniruzzamanshimul/how-to-create-a-new-user-and-configure-both-key-based-and-password-based-authentication-on-oracle-765643644249)