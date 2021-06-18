# Edit this configuration file to define what should be installed on
# your system. You can apply it with 'nixos-rebuild switch' (--upgrade)
# Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  unstableTarball =
    fetchTarball
      https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
    
  # Get mesa running:
   mesa_version = "21.1.0";
   mesa_src = pkgs.fetchurl {
     url = "https://mesa.freedesktop.org/archive/mesa-${mesa_version}.tar.xz";
     sha256 = "1y0z3ff685ql2l3pqyfrbh0j6ipr64vh0d0h7pnkl3cp487g2a01";
   };
   mesa_21_1 = pkgs.mesa.overrideAttrs (a: { src = mesa_src; version = mesa_version; patches = sublist 1 2 a.patches; });
   mesa_21_1_32 = pkgs.pkgsi686Linux.mesa.overrideAttrs (a: { src = mesa_src; version = mesa_version; patches = sublist 1 2 a.patches; });
 in
{
    hardware = {
        opengl = {
           driSupport32Bit = true;
           package = mkForce mesa_21_1.drivers;
           package32 = mkForce mesa_21_1_32.drivers;
        };
    };
  }

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Make use of the Zen kernel:
  nixpkgs.config.packageOverrides = in_pkgs :
    {
      linuxPackages = in_pkgs.linuxPackages_zen.kernel;
    };

  # Networking:
   networking.hostName = "halcek"; # Define your hostname.
   networking.networkmanager.enable = true; # Sets-up the wireless network
   networking.wireless.enable = true;
   
  # Workaround for the no network after resume issue:
    powerManagement.resumeCommands = ''
    ${pkgs.systemd}/bin/systemctl restart wpa_supplicant
    ${pkgs.systemd}/bin/systemctl restart networkmanager
  '';
   
   # Sets the time zone:
   time.timeZone = "Europe/Bratislava";
   services.ntp.enable # Sync time over network
   

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

  # Allow updating firmware:
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.synaptics.enable = true;
  
  # Specifies graphics card setting, Intel here:
  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.useGlamor = true;

  # Enable the GNOME Desktop Environment:
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = [ pkgs.gnome.cheese pkgs.gnome.gnome-music pkgs.gnome.gnome-terminal pkgs.gnome.gedit pkgs.gnome.gnome-calendar pkgs.gnome.totem pkgs.gnome.tali pkgs.gnome.iagno pkgs.gnome.hitori pkgs.gnome.atomix pkgs.gnome-tour ];

  # Configure keymap in X11:
   services.xserver.layout = "us,gb,sk";
   services.xserver.xkbOptions = "eurosign:e";

  # Allow UNfree licenses:
    nixpkgs.config.allowUnfree = true;

  # Automatic system updates:
  system.autoUpgrade.enable = true;

  # OpenGL, with Intel integrated GPU:
   hardware.opengl.enable = true;
   hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
    vaapiVdpau
    libvdpau-va-gl
    intel-media-driver
  ];
    driSupport32Bit = true;

  # Enable CUPS to print documents:
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
   hardware.pulseaudio.support32Bit = true;
   hardware.pulseaudio.package = pkgs.pulseaudioFull;
   hardware.pulseaudio.zeroconf.discovery.enable = true;
   services.pipewire.enable = true;
   
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
   
  # List of the packages installed in system profile. To search, run:
  # $ nix search wget
   environment.systemPackages = with pkgs; [

  # Editors and writig:
     emacs  # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed>
     vnote  # For larger research documents
     trilium-desktop # Hierarchically linked notes
     zim # A personal knowledge base
     obsidian # Note connections
     pandoc # A universal document converter
     ghostscript
     gnome.gspell
     xed-editor # A less basic, basic text editor 
     libreoffice-fresh
     koreader # An ebook, and PDF reader

   # Spell-checkers:
     aspellDicts.en
     hunspellDicts.en-gb-large
     aspellDicts.sk
     hunspellDicts.sk-sk

   # VPNs and Firewall:
     openvpn
     mullvad-vpn
     pptp
     openssl
     libressl
     gnupg
     pinentry
     certbot # Renews fresh SSL certificates
     
   # Internet:
     firefox-wayland
     gnome-feeds # An RSS reader
     filezilla # For FTP and FTPS connections
     transmission-gtk # P2P file transfer
     croc # Computer-to-computer file transfer
     
   # Communication:
     mirage-im # A Matrix.org client
     signal-desktop
     skype
     dino # A XMPP client
     gnome.polari # An IRC client
     tootle # A client for the fediverse
     cawbird # For Twitter
     
   # Media
     cozy # Audiobooks
     pragha # A competent music player
     vlc
     python38Packages.python-vlc
     python39Packages.python-vlc
     celluloid # Front-end for MPV
     youtube-dl # An internet video downloader
     sublime-music # A subsonic client
     reaper # An affordable DAW

    # System
      git
      wget
      unzip
      unrar
      gnutar
      alacritty # GPU accelerated
      zenith # System information
      neofetch
      mesa # For 3D graphics (see beginning of spec.)
      driversi686Linux.mesa
      wpa_supplicant (see 'Networking' section)
      usbutils
      pciutils
      webkitgtk
      pantheon.elementary-calendar
      gnome.mutter
      gnome.gpaste
      qgnomeplatform
      gnomeExtensions.hide-top-bar
      gnomeExtensions.material-shell
      gnomeExtensions.showtime-horizontal
      gnomeExtensions.new-mail-indicator
      cinnamon.xapps
   ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
   programs.mtr.enable = true;
   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };
   
  # List the services that you want enabled:
  
  # Power management:
   services.tlp.enable = true;

  # Enable the OpenSSH daemon:
   services.openssh.enable = true;
   services.mullvad-daemon.enable = true; # Make sure Mullvad's ready
   
  # Enable a smart card reader:
   services.pcscd.enable = true;
   
  # Enable touchpad support:
   services.xserver.libinput.enable = true;
   services.gpm.enable = true; # Generic mouse support

  # Enable Bluetooth:
   hardware.bluetooth.enable = true;

  # Enable auto-mouting of connected (USB/SDC) devices:
   services.devmon.enable = true;
   services.dbus.enable = true;
   services.smartd.enable = true;
   
  # Enable automatic updatedb:
   services.locate.enable = true;
   
  # Enable building of packages simultaneously:
   enableParallelBuilding = true;

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
