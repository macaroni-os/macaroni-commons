// Small Init + Eudev for embedded
// Based on the original work of Ettore Di Giacinto
package main

import (
	"log"
	"os"
	"os/exec"
	"strings"
	"syscall"

	"github.com/u-root/u-root/pkg/libinit"
)

type initCmds struct {
	cmds []*exec.Cmd
}

var (
	debug   = func(string, ...interface{}) {}
	modules = []string{
		"af_packet",
		"cdrom",
		"dm_mod",
		"e1000e",
		"e1000",
		"overlay",
		"ahci",
		"virtio_blk",
		"virtio_pci",
		"pata_acpi",
		"ahcpi-plaftorm",
		"libahcpi-platform",
		"ata_piix",
		"ohci_pci",
		"ehci_pci",
		"loop",
		"ext4",
		"isofs",
		"squashfs",
		"ata_generic",
		"sd_mod",
		"sr_mod",
		"ext2",
		"uas",
		"usb_storage",
		"usbcore",
		"usb_common",
		"ehci_hcd",
		"uhci_hcd",
		"ohci_hcd",
		"paride",
		"scsi_mod",
		"ehci_pci",
		"xhci_pci",
		"xhci_hcd",
		"virtio_blk",
		"virtio_pci",
		"part_msdos",
		"usbms",
		"usbhid",
		"hid-generic",
		"vfat",
		"nls_iso8859_1",
		"nls_cp437",
	}

	dirs = []string{"/mnt", "/run"}
)

func modprobe(s string) (string, error) {
	cmd := exec.Command("modprobe", s)
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}
	return string(stdoutStderr), nil
}

func depmod() (string, error) {
	cmd := exec.Command("depmod", "-a")
	stdoutStderr, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}
	return string(stdoutStderr), nil
}

func loadModules() error {
	// TODO: Report failed kernel modules load to a file available in
	// runtime /var/log
	// TODO: run depmod() if no alias file is found
	out, _ := depmod()
	log.Println(out)
	log.Println("Loading kernel modules", strings.Join(modules, " "))
	for _, m := range modules {
		modprobe(m) // Skip error and log output for now
	}

	// probe for modules to load udev-style
	drivers := probeKernelModules()
	log.Println("Loading detected kernel modules", strings.Join(drivers, " "))
	for _, k := range drivers {
		modprobe(k) // Skip error and log output for now
	}
	return nil
}

func ensureDirs() error {
	for _, d := range dirs {
		os.MkdirAll(d, os.ModePerm)
	}
	return nil
}

func sysExec() {
	env := os.Environ()
	binary, lookErr := exec.LookPath("bash")
	if lookErr != nil {
		panic(lookErr)
	}

	execErr := syscall.Exec(binary, []string{"bash", "/loader"}, env)
	if execErr != nil {
		panic(execErr)
	}
}

func main() {
	log.SetPrefix(">>> ")

	log.Printf("Funtoo Macaroni OS initialization...")

	libinit.SetEnv()
	// CreateRootfs creates a symlink to /dev/pts/ptmx
	// and thus have to be chmod to 666: https://www.kernel.org/doc/Documentation/filesystems/devpts.txt
	libinit.CreateRootfs()
	os.Chmod("/dev/pts/ptmx", 0666)

	libinit.NetInit()

	ensureDirs()
	loadModules()

	sysExec()
	syscall.Sync()

	Halt()
}
