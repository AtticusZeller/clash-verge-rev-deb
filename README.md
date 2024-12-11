# DEB Index

auto sync debs

## Supported packages

- Clash Verge Rev
- obsidian

## Add repo

### Install

```bash
curl -fsSL https://atticuszeller.github.io/deb-index/install.sh | sudo bash
```

or manually

```bash
# Add GPG key
curl -fsSL https://atticuszeller.github.io/deb-index/public.key | sudo apt-key add -

# Add repository
echo "deb https://atticuszeller.github.io/deb-index stable main" | sudo tee /etc/apt/sources.list.d/deb-index.list

# Update package lists
sudo apt update
```

## Uninstall

```bash
curl -fsSL https://atticuszeller.github.io/deb-index/uninstall.sh | sudo bash
```

## Intsall package

```bash
sudo apt install obsidian
```
