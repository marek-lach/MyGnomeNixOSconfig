# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the latest kernel

  # boot.kernelPackages will use linuxPackages by default, so no need to define it
  nixpkgs.config.packageOverrides = in_pkgs :
    {
      linuxPackages = in_pkgs.linuxPackages_latest;
    };

  # Networking:

   networking.hostName = "halcek"; # Define your hostname.
   networking.networkmanager.enable = true; # Sets-up the wireless network
   wifi.powersave = false;
   
  # Workaround for the no network after resume issue:
  powerManagement.resumeCommands = ''
    ${pkgs.systemd}/bin/systemctl restart wpa_supplicant
  '';
   
   # Sets your time zone.
   time.timeZone = "Europe/Bratislava";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp2s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
   i18n.defaultLocale = "en_GB.UTF-8";
   console = {
     font = "Lat2-Terminus16";
     keyMap = "us";
   };

  # Allow updating firmware
  hardware.enableAllFirmware = true;
  services.fwupd.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
  # Specifies graphics card setting, Intel here:
  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.useGlamor = true;

  # Enable the GNOME Desktop Environment:
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  
  # Set the default user shell to fish: 
    {   
      programs.fish.enable = true;
      users.defaultUserShell = pkgs.fish;
    }

  # Configure keymap in X11
   services.xserver.layout = "gb,sk";
   services.xserver.xkbOptions = "eurosign:e";

  # Allow UNfree licenses
    nixpkgs.config.allowUnfree = true;

  # Automatic system updates
  system.autoUpgrade.enable = true;

  # OpenGL with Intel integrated GPU
   hardware.opengl.enable = true;
   hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
  ];

  # Enable CUPS to print documents.
   services.printing.enable = true;
   
   # Font settings:
   fonts.fontconfig.enable = true;
   fonts.fontconfig.dpi=96; # font size in xterm console
   fonts = {
    fontDir = {
      enable = true;
    };
    enableGhostscriptFonts = true;
    };

  # Enable sound:
   sound.enable = true;
   hardware.pulseaudio.enable = true;
   hardware.pulseaudio.package = pkgs.pulseaudioFull;

  # Enable touchpad support:
   services.xserver.libinput.enable = true;
   
  # Required for screen-lock-on-suspend functionality.
  services.logind.extraConfig = ''
    LidSwitchIgnoreInhibited=False
    HandleLidSwitch=suspend
    HoldoffTimeoutSec=10
  '';
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
   users.users.halcek = {
     isNormalUser = true;
      home = "/home/halcek";
     extraGroups = [ "wheel" "audio" "video" "network" "networkmanager"]; # Enable ‘sudo’ for the user.
   };
   
   # List packages installed in system profile. To search, run:
  # $ nix search wget
   environment.systemPackages = with pkgs; [

  # Editors and writig:
     emacs  # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed>
     vnote  # For larger research documents
     trilium-desktop # Hierarchically linked notes
     pandoc # A universal document converter
     ghostscript
     gnome.gspell
     libreoffice-fresh-unwrapped

   # Spell-checkers:
     aspellDicts.en
     hunspellDicts.en-gb-large
     aspellDicts.sk
     hunspellDicts.sk-sk

   # VPNs and Firewall:
     openvpn
     pptp
     openssl
     libressl
     gnupg
     pinentry
     certbot
     
   # Internet:
     firefox
     filezilla # For FTP and FTPS connections
     transmission-gtk # P2P file transfer
     croc # Computer-to-computer file transfer
     
   # Communication:
     mirage-im # A Matrix.org client
     signal-desktop
     dino # A XMPP client
     
   # Media
     cozy
     vlc
     celluloid
     python39Packages.python-vlc
     sublime-music
     ocenaudio
     reaper

    # System
      git
      wget
      alacritty
      zenith
      neofetch
      mesa
      wpa_supplicant
      webkitgtk
      gnomeExtensions.hide-top-bar
      gnomeExtensions.material-shell
      gnomeExtensions.new-mail-indicator
      youtube-dl
   ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
   programs.mtr.enable = true;
   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };
   
  # Provides acess to the NixOS unstable for certain apps, if necessary:
   
   packageOverrides = pkgs: {
    unstable = import <nixos-unstable> {
      config = config.nixpkgs.config;
    };
  };
   
   # List the services that you want to enable:

  # Enable the OpenSSH daemon:
   services.openssh.enable = true;
   
  # Start ssh-agent as a systemd user service
   programs.ssh.startAgent = true;
   
  # Enable a smart card reader
   services.pcscd.enable = true;

  # Enable Bluetooth:
   hardware.bluetooth.enable = true;

  # Enable auto-mouting of connected USB devices
   services.devmon.enable = true;
   
  # Enable automatic updatedb
   services.locate.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
