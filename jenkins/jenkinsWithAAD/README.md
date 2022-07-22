# Jenkins Authentication and Authorization with Azure AD
## App Registration
1. Login to Azure portal: https://portal.azure.com/
2. Click on **Azure Active Directory** > **App registrations** > **New registration**
3. Give Name: **_Jenkins_**
4. Supported account types: **Accounts in this organizational directory only (Default Directory only - Single tenant)**
5. Redirect URI: **Web** : **_https://jenkins.hackwithv.com/securityRealm/finishLogin_** 
6. Click on **Register**

## Set Authentication in Azure AD
1. Click on **Azure Active Directory** > **App registrations** > **Jenkins**
2. **Authentication** > **Front-channel logout URL** : **_https://jenkins.hackwithv.com_**
3. Enable **ID tokens (used for implicit and hybrid flows)**
4. Click on **Save**

## Set Permission
1. Click on **Azure Active Directory** > **App registrations** > **Jenkins**
2. Copy **Application (client) ID** (copy1)
3. Copy **Directory (tenant) ID** (copy2)
4. Click on **API permissions** > **Add a permission** > **Microsoft Graph**
5.  **Application permissions** > **Directory** > **Directory.Read.All**
6.  **Grant admin consent for Default Directory** > **Yes**

## Create secrets
1. Click on **Azure Active Directory** > **App registrations** > **Jenkins** 
2.  **Certificates & secrets** > **New client secret** > **Add**
3. Copy **Secret value** (copy3)


## Configure Authentication in Jenkins
1. Login to Jenkins: https://jenkins.hackwithv.com
2. Click on **Dashboard** > **Manage Jenkins** > **Configure System**
3. Set Jenkins URL: **_https://jenkins.hackwithv.com/_** 
4. Click on **Save**
5. Click on **Dashboard** > **Manage Jenkins** > **Configure Global Security**
6. Choose Security Realm: **Azure Active Directory**
7. Provide details
```
Client ID    : <Paste1 client ID from AAD>
Client Secret: <Paste3 client Secret from AAD>
Tenant       : <Paste2 tenant ID from AAD>
```
8. Click on **Save**

## Configure Authorization in Jenkins
1. Click on **Dashboard** > **Manage Jenkins** > **Configure Global Security**
2. In Authorization choose : **Azure Active Directory Matrix-based security**
3. Based on requirements provide access to user
4. Click on **Save**