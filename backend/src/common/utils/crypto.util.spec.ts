import { encrypt, decrypt } from './crypto.util';

describe('CryptoUtil', () => {
  const secretKey = 'my_super_secret_papo_key';
  const originalText = '0xabc123thisisaprivatekey';

  it('should encrypt and decrypt text successfully', () => {
    const encrypted = encrypt(originalText, secretKey);
    expect(encrypted).toContain(':');
    
    const decrypted = decrypt(encrypted, secretKey);
    expect(decrypted).toBe(originalText);
  });

  it('should fail decryption if a wrong key is used', () => {
    const encrypted = encrypt(originalText, secretKey);
    expect(() => {
      decrypt(encrypted, 'wrong_secret_key');
    }).toThrow();
  });

  it('should fail decryption if the input format is invalid', () => {
    expect(() => {
      decrypt('invalid-format-no-colon', secretKey);
    }).toThrow('Invalid encrypted text format');
  });
});
