# frozen_string_literal: true

describe 'WalletClient::Ripple' do
  describe '#create_address!' do
    let(:client) { WalletClient[wallet] }
    let(:wallet) { Wallet.find_by_blockchain_key('xrp-testnet') }
    let(:create_address) { client.create_address! }

    it 'create valid address with destination_tag' do
      address = create_address[:address]
      expect(normalize_address(address)).to eq wallet.address
      expect(destination_tag_from(address).to_i).to be > 0
    end
  end
end

def normalize_address(address)
  address.gsub(/\?dt=\d*\Z/, '')
end

def destination_tag_from(address)
  address =~ /\?dt=(\d*)\Z/
  $1.to_i
end
