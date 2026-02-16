# Umbrel OS in Docker

This project builds a runnable container image from the official Umbrel OS
Raspberry Pi 5 image and runs it with `init` inside Docker. It is designed for
my own Pi 5 setup, but it should be adaptable to other architectures.

## Status

- Supported: ARM64 Raspberry Pi 5 image (the current Umbrel OS Pi 5 release)
- Not supported yet: x86/x64 images (possible, but not implemented here)

## How it works

The `Dockerfile` downloads the official Umbrel OS Pi 5 image zip, extracts the
largest non-extended partition from the disk image, and reconstructs a root
filesystem with `debugfs`. The final container image is built from that rootfs
and runs `/sbin/init`.

## Requirements

- Docker (or Podman with compatible flags)
- Linux host with cgroups enabled
- Enough disk space for the image download and extraction (several GB)
- Network access to `https://download.umbrel.com`

## Quick start

```bash
docker compose build
docker compose up -d
```

Access the Umbrel UI at:

```
http://localhost:80
```

## Configuration (docker-compose.yml)

Key settings in `docker-compose.yml`:

- `privileged: true` is required for `init` and system services
- `ports: 80:80` exposes the web UI
- `tmpfs: /run, /tmp` for runtime directories
- `volumes:`
  - `/sys/fs/cgroup:/sys/fs/cgroup:rw` for cgroup access
  - `./umbrel:/home/umbrel` for persistent Umbrel data

You can change the host port or data path by editing `docker-compose.yml`.

## Notes

- The build downloads the full Umbrel OS image on every rebuild unless your
  Docker layer cache is preserved.
- First build can take a while depending on your network and disk speed.
- This is not an official Umbrel project; it uses the publicly available
  Umbrel OS image.

## Troubleshooting

- Build fails downloading image:
  - Check network access to `download.umbrel.com`
- Container exits quickly:
  - Ensure cgroups are enabled on the host
  - Verify the container is running in privileged mode
- Check logs:
  ```bash
  docker compose logs -f
  ```

## Adapting to x86

It should be possible to support x86/x64 by changing the downloaded image URL
and validating the partition selection logic for that image layout. This repo
does not provide that yet.
