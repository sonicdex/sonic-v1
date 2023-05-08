
echo "Install Dependency tools"
apt -yq update
apt -y install --no-install-recommends curl ca-certificates \
            build-essential pkg-config libssl-dev llvm-dev \
            liblmdb-dev clang cmake git jq

echo "Install Node and Yarn"
curl -sL https://deb.nodesource.com/setup_16.x | sudo bash -
apt-get install -y nodejs
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn
yarn global add serve

echo "Install DFX"
DFX_VERSION "0.9.3" sh -ci "$(curl -L https://smartcontracts.org/install.sh)"
chown -R $(whoami) /usr/local/bin/dfx

echo "Install Rust"
curl --fail https://sh.rustup.rs/ -sSf \
        | sh -s -- -y --default-toolchain 1.61.0-x86_64-unknown-linux-gnu --no-modify-path
source "$HOME/.cargo/env"
rustup default 1.61.0-x86_64-unknown-linux-gnu
rustup target add wasm32-unknown-unknown
cargo install ic-cdk-optimizer