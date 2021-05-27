{ config, pkgs, ... }:

{

  virtualisation = {
    libvirtd = {
      enable = true;
      qemuVerbatimConfig = ''
        user = "will"
        group = "kvm"

        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
          "/dev/rtc","/dev/hpet",
          "/dev/input/by-id/usb-Razer_Razer_BlackWidow_Chroma-event-kbd",
          "/dev/input/by-id/usb-Logitech_USB_Receiver-if02-event-mouse",
        ]
      '';
    };

    docker.enable = true;
  };
}
