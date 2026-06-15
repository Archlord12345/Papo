const sdk = require('node-appwrite');

// Configuration from appwrite_config.dart
const endpoint = 'https://cloud.appwrite.io/v1';
const projectId = '6a2e769b001cc126b097';
const apiKey = 'standard_72b37c210d7afb99470a1afef7a55410da2865bc100a51c5833424029a009a7fa990bbc1b693da727fcde94a8b2f800ee5602aa2bbfc985c5b3e1f45bd383db6f3b76deb5ed7816d61db1592d924c52bd6a8790035bb136a4b657944631342ab5b2034a8fe439a88d97426ff7cc0ad85671cb6adcd96767bf24b64dbe128bc7f';
const databaseId = '6a2e7d980035f3f178b1';

const client = new sdk.Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);

const databases = new sdk.Databases(client);
const storage = new sdk.Storage(client);

async function setup() {
    console.log('--- Initialisation Appwrite PAYPOINT ---');

    try {
        // 1. Create Collections if they don't exist
        const collections = [
            { id: 'users_profile', name: 'Users Profiles' },
            { id: 'transactions', name: 'Transactions' },
            { id: 'notifications', name: 'Notifications' },
            { id: 'balances', name: 'Balances' },
            { id: 'devices', name: 'Devices' },
            { id: 'wallets', name: 'Wallets' },
            { id: 'biometrics', name: 'Biometrics' }
        ];

        for (const col of collections) {
            try {
                await databases.getCollection(databaseId, col.id);
                console.log(`Collection ${col.name} existe déjà.`);
            } catch (e) {
                await databases.createCollection(databaseId, col.id, col.name);
                console.log(`Collection ${col.name} créée.`);
            }
        }

        // 2. Setup Attributes for users_profile
        const userAttributes = [
            { key: 'userId', type: 'string', size: 255, required: true },
            { key: 'name', type: 'string', size: 255, required: true },
            { key: 'phone', type: 'string', size: 50, required: true },
            { key: 'kycStatus', type: 'string', size: 20, required: false, default: 'none' },
            { key: 'avatarUrl', type: 'string', size: 1000, required: false },
            { key: 'isMerchant', type: 'boolean', required: false, default: false }
        ];

        for (const attr of userAttributes) {
            try {
                if (attr.type === 'string') {
                    await databases.createStringAttribute(databaseId, 'users_profile', attr.key, attr.size, attr.required, attr.default);
                } else if (attr.type === 'boolean') {
                    await databases.createBooleanAttribute(databaseId, 'users_profile', attr.key, attr.required, attr.default);
                }
                console.log(`Attribut ${attr.key} ajouté à users_profile.`);
            } catch (e) {
                console.log(`Attribut ${attr.key} déjà présent ou erreur.`);
            }
        }

        // 3. Create Storage Bucket
        try {
            await storage.getBucket('user_data');
            console.log('Bucket user_data existe déjà.');
        } catch (e) {
            await storage.createBucket('user_data', 'User Data', ['read("any")', 'write("any")'], false);
            console.log('Bucket user_data créé.');
        }

        console.log('--- Setup terminé avec succès ---');
    } catch (error) {
        console.error('Erreur globale during setup:', error);
    }
}

setup();
