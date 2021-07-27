# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
# After adding the unstable channel in $HOME/.nix-channels, run: nixos-rebuild switch --upgrade

{ config, pkgs, ... }:

let
 ciSystems = [
    "x86_64-linux"
    "aarch64-linux"
  ]; # Specifies architecture

nixos-unstable =
      fetchTarball
      https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
NUR = 
  fetchTarball 
    https://github.com/nix-community/NUR/archive/master.tar.gz;
  
 in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

   # Import all the repositories: 

    nixpkgs.config = {
    packageOverrides = pkgs: {
    linuxPackages = pkgs.linuxPackages_testing_bcachefs; # Use the latest kernel
    NUR = import NUR {
    nixos-unstable = import nixos-unstable {
    
    config = config.nixpkgs.config;
     };
    };
   };
  };
  
 # Load extra kernel modules:
  boot.kernelModules = [ "acpi_call" "cryptd" "ledtrig_audio" "kvm-intel" "aesni_intel" "intel_powerclamp" "tmp_crb" "tmp_tis" "tmp_tis_core" "coretemp" "intel_cstate" "intel_uncore" "intel_spi" "intel_spi_platform" "snd_intel_dspcfg" "snd_intel_sdw_acpi" "intel_rapl_msr" "intel_rapl_common" "intel_pmc_bxt" "snd_hda_intel" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.extraModprobeConfig = ''
  options snd_hda_intel power_save=1 iwlwifi power_save=N pci=realloc
'';
  boot.initrd.checkJournalingFS = true; # Check-up on the file system
  
 # Use the systemd-boot EFI boot loader.
  boot.kernelPackages = pkgs.linuxPackages_testing_bcachefs; # Boot the kernel first
  hardware.firmware = [ pkgs.alsa-firmware ]; # Initialize ALSA firmware
  boot.loader.systemd-boot.enable = true;
  systemd.services.systemd-udev-settle.enable = false;
  boot.loader.efi.efiSysMountPoint = "/boot/";
  systemd.services.NetworkManager-wait-online.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "btrfs" "ext4" ];
  boot.initrd.network.enable = true; # Enable network at boot

  # Better SSD support:
   services.fstrim.enable = true; # Enable TRIM
   fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];   

  # Networking:
  networking.hostName = "halcek"; # Define your hostname.
  networking.networkmanager.enable = true; # Sets-up the wireless network
  networking.enableIPv6 = true;
  networking.interfaces.wlp1s0.useDHCP = true;
  services.mullvad-vpn.enable = true;
   
  # Workaround for the no network after resume issue:
   powerManagement.resumeCommands = ''
   ${pkgs.systemd}/bin/systemctl restart networkmanager
   ${pkgs.systemd}/bin/systemctl restart wpa_supplicant
  '';

   # Security:
   security.audit.enable = true;
   security.auditd.enable = true;
   
   # Sets the time zone:
   time.timeZone = "Europe/Bratislava";
   time.hardwareClockInLocalTime = true;
    
    # Select internationalisation properties.
    i18n.defaultLocale = "en_GB.UTF-8";
    console = {
    font = "Lat2-Terminus16";
     keyMap = "us";
   };
   
  # Allow updating firmware:
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;
  hardware.cpu.intel.updateMicrocode = true; # For Intel-only CPUs
   
 # Specifies graphics card setting, Intel here:
  services.xserver.videoDrivers = [ "intel" ];
  services.xserver.useGlamor = true;
  
 # OpenGL, with Intel integrated GPU:
  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
    vaapiVdpau
    libvdpau-va-gl
    intel-media-driver
  ];

  # Power Management:
  powerManagement.enable = true;
  services.thermald.enable = true;
  services.upower.enable = true;
  services.acpid.enable = true;
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;
 
  # Enable the X11 windowing system.
  services.xserver.enable = true;  

  # Enable the GNOME Desktop Environment:
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = [ pkgs.gnome.cheese pkgs.gnome-photos pkgs.gnome.gnome-music pkgs.gnome.gnome-terminal pkgs.gnome-multi-writer pkgs.gnome.gedit pkgs.epiphany pkgs.evince pkgs.gnome.gnome-characters pkgs.gnome.totem pkgs.gnome.tali pkgs.gnome.iagno pkgs.gnome.hitori pkgs.gnome.atomix pkgs.gnome-tour ];
  services.gnome.evolution-data-server.enable = true;
  services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
  [org.gnome.desktop.peripherals.touchpad]
  click-method='default'
''; # Mousepad right-click action works

  # Configure keymap in X11:
   services.xserver.layout = "us,gb,sk";
   services.xserver.xkbOptions = "eurosign:e";
   
  # Enable printing:
  # Note that the CUPS Web UI for configuration can be accessed at: http://localhost:631
  services.printing = {
    enable = true;
  };
  programs.system-config-printer.enable = true;

  # Automatic system updates:
  system.autoUpgrade.enable = true;

  # Font settings:
  fonts.fontconfig.enable = true;
  fonts.fontconfig.dpi=96; # font size in xterm console
  fonts.fonts = with pkgs; [
	  pkgs.font-awesome
          pkgs.fira
          pkgs.montserrat
  ];
   fonts = {
    fontDir = {
      enable = true;
    };
    enableGhostscriptFonts = true;
    };

 # Enable sound:
   sound.enable = true;
   hardware.pulseaudio.enable = true;
   nixpkgs.config.pulseaudio = true;
   hardware.pulseaudio.support32Bit = true;
   hardware.pulseaudio.package = pkgs.pulseaudioFull;
   hardware.pulseaudio.zeroconf.discovery.enable = true;
   hardware.pulseaudio.extraConfig = ''
    load-module module-equalizer-sink
    load-module module-dbus-protocol
    load-module module-switch-on-connect # Switch automatically when Bluetooth connects
  '';
  
 # Run periodic garbage collection of the Nix store cache:
 nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

 # Define the user account here. Don't forget to set a password with 'useradd' & ‘passwd’.
  
   users.users.halcek = {
     isNormalUser = true;
      home = "/home/halcek";
      shell = pkgs.fish;
      extraGroups = [ "wheel" "audio" "jackaudio" "sound" "video" "network" "networkmanager" "input" ]; # Enable ‘sudo’ for the use>
   };

# List packages installed in system profile. To search, run:
  # $ nix search wget
    environment.systemPackages = with pkgs; [
    
    # Editors and writig:
     pkgs.emacs  # The Nano editor is also installed by default
     auctex # Emacs mode for writing LaTex
     pkgs.apostrophe # Distraction-free markdown editor
     pkgs.zettlr # A markdown document processor
     pkgs.vnote  # For larger research documents
     pkgs.trilium-desktop # Hierarchically linked notes
     pkgs.zim # A personal knowledge base
     pkgs.obsidian # Note connections
     pandoc # A universal document converter
     ghostscript
     tectonic # The LaTex typesetting, and rendering engine
     gnome.gspell # Spell-checking capabilities for GNOME
     pkgs.xed-editor # A less basic, basic text editor 
     pkgs.libreoffice-fresh
     pkgs.koreader # An ebook, and PDF reader
     
   # Spell-checkers:
     aspellDicts.en
     hunspellDicts.en-gb-large
     aspellDicts.sk
     hunspellDicts.sk-sk
     
     # VPNs and Firewall:
     pkgs.openvpn
     pkgs.mullvad-vpn # A MullvadVPN client
     pkgs.protonvpn-gui # Client for ProtonVPN
     pptp
     openssl
     libressl
     gnupg
     pinentry
     certbot # Renews fresh SSL certificates
     
   # Internet:
     pkgs.firefox-wayland
     pkgs.gnome-feeds # An RSS reader
     pkgs.filezilla # For FTP and FTPS connections
     pkgs.transmission-gtk # P2P file transfer
     croc # Computer-to-computer file transfer
     
   # Communication:
     pkgs.mirage-im # A Matrix.org client
     pkgs.signal-desktop
     pkgs.teams
     pkgs.zoom-us # A necessary evil
     pkgs.skype
     pkgs.dino # A XMPP client
     pkgs.gnome.polari # An IRC client
     pkgs.tootle # A client for the fediverse
     pkgs.cawbird # For Twitter
     
     # Media:
     pkgs.cozy # Audio-books
     pkgs.gnome-podcasts
     pkgs.vlc # Media-files player
     python38Packages.python-vlc
     python39Packages.python-vlc
     pkgs.celluloid # Front-end for MPV
     pkgs.flacon # Divide an audio file into songs
     youtube-dl # An internet video downloader
     pkgs.sublime-music # A subsonic client
     reaper # An affordable DAW editor
     pavucontrol # PulseAudio user control     

     # Graphics manipulation:
     pkgs.gimp    

     # System:
     git
     wget
     unzip
     unrar
     gnutar
     mate.engrampa # Archiver front-end
     pkgs.kitty # GPU accelerated terminal emulator
     fish # The best interactive shell
     zenith # CLI System information
     neofetch
     mesa # For 3D graphics (see beginning of spec.)
     driversi686Linux.mesa
     wpa_supplicant
     usbutils
     pciutils
     webkitgtk
     gnome.mutter # The Gnome Window Manager
     vulkan-headers
     vulkan-loader # Load Vulkan globally
     firmwareLinuxNonfree # Linux firmware
     uefi-firmware-parser
     systemd-wait
     libgnome-keyring
     qgnomeplatform # QT apps to look alike with GTK
     gnomeExtensions.hide-top-bar
     gnomeExtensions.new-mail-indicator
     cinnamon.xapps
   ];
   
   # Enable the friendly inter shell:
    programs.fish.enable = true;
   
 nixpkgs.config.allowUnfree = true; # Unfree for pre-created users    

  # Some programs need SUID wrappers, can be configured further or are started in user sessions.
    programs.mtr.enable = true;
    programs.gnupg.agent = {
    enable = true; 
    enableSSHSupport = true; 
  }; 

  # List the services that you want to enable:
   
  # Enable the OpenSSH daemon:
   services.openssh.enable = true;
   
   # Enable a smart card reader:
   services.pcscd.enable = true;
   
  # Enable touchpad support:
   services.xserver.libinput.enable = true;
   services.gpm.enable = true; # Generic mouse support

  # Enable Bluetooth:
   hardware.bluetooth.enable = true;
   services.blueman.enable = true;

  # Enable auto-mouting of connected (USB/SDC) devices:
   services.devmon.enable = true;
   services.dbus.enable = true;
   services.smartd.enable = true;
   
  # Enable automatic updatedb:
   services.locate.enable = true;
   
  # Gnome Virtual File System - pretty essential I/O service, many apps need it for stuff like trash
   services.gvfs.enable = true;
   
  # Open ports in the firewall:
  # networking.firewall.allowedTCPPorts = [ 53 80 88 442 433 443 444 445 514 554 5060 5228 5353 5357 8384 8443 31416 4419999 64738 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Disable the firewall service itself:
    networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
