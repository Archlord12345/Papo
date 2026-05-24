import { BlockchainService } from './blockchain.service';
import { ethers } from 'ethers';

describe('BlockchainService', () => {
  let service: BlockchainService;

  beforeEach(() => {
    service = new BlockchainService();
  });

  it('should generate a valid wallet address and keys', () => {
    const wallet = service.generateWallet();
    expect(wallet.address).toBeDefined();
    expect(wallet.privateKey).toBeDefined();
    expect(wallet.publicKey).toBeDefined();
    expect(ethers.isAddress(wallet.address)).toBe(true);
  });

  it('should successfully verify a valid cryptographic signature', async () => {
    const generated = service.generateWallet();
    const message = 'senderAddress:receiverAddress:amount:tokenId:txId';
    
    // Sign the message using the generated private key
    const walletSigner = new ethers.Wallet(generated.privateKey);
    const signature = await walletSigner.signMessage(message);

    const isValid = service.verifySignature(generated.address, message, signature);
    expect(isValid).toBe(true);
  });

  it('should fail verification for mismatched message or address', async () => {
    const generated = service.generateWallet();
    const message = 'senderAddress:receiverAddress:amount:tokenId:txId';
    
    const walletSigner = new ethers.Wallet(generated.privateKey);
    const signature = await walletSigner.signMessage(message);

    // Mismatched message
    const isValidMismatchedMessage = service.verifySignature(
      generated.address,
      message + '-altered',
      signature,
    );
    expect(isValidMismatchedMessage).toBe(false);

    // Mismatched address
    const anotherAddress = '0x0000000000000000000000000000000000000000';
    const isValidMismatchedAddress = service.verifySignature(
      anotherAddress,
      message,
      signature,
    );
    expect(isValidMismatchedAddress).toBe(false);
  });

  it('should anchor transaction and return a mock receipt', async () => {
    const mockReceipt = await service.anchorTransaction(1, '0xdatahash');
    expect(mockReceipt).toBeDefined();
    expect(mockReceipt.startsWith('0x')).toBe(true);
  });
});
