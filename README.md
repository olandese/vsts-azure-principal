# vsts-azure-principal

See my [blog post](http://blog.olandese.nl/2017/01/30/a-better-way-and-script-to-add-a-service-principal-in-azure-for-vsts/)

*NOTE: If the principal (application name) already exists then the password will not be updated.*

## Parameters Sets examples

### CreateVSTSPrincipalOnly

Create only an Azure AD Application/Principal without any role grant:

```powershell
.\createservicesprincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password "ThePassword"
```

### CreateVSTSPrincipalWithExistingResourceGroups

Create an Azure AD Application/Principal and grants the Role on the specified existing Resource Groups (if the Resource Groups do not exists no error will be thrown, they will just be ignored):

``` powershell
.\createservicesprincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password "ThePassword" -resourceGroupNames "ResourceGroupName1","ResourceGroupName2","etc"
```

### CreateVSTSPrincipalAndResourceGroups

Create an Azure AD Application/Principal and the specified Resource Groups at the provided location, grants the Role to the Resource Groups:

``` powershell
.\createservicesprincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password "ThePassword" -resourceGroupNames "ResourceGroupName1","ResourceGroupName2","etc" -createResourceGroups -location "West Europe"
```

### CreateVSTSPrincipalAndResourceGroups with Active Directory Groups

Create an Azure AD Application/Principal and the specified Resource Groups at the provided location, grants the Role to the Resource Groups. Also grants the AD groups to the Resource Groups:

``` powershell
.\createservicesprincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password "ThePassword" -resourceGroupNames "ResourceGroupName1","ResourceGroupName2","etc" -adGroupNames "AdGroupName1", "AdGroupName2", "etc" -createResourceGroups -location "West Europe"
```

### CreateVSTSPrincipalSubscriptionLevel

Create an Azure AD Application/Principal and grants the Role at subscription level:

``` powershell
.\createservicesprincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password "ThePassword" -grantRoleOnSubscriptionLevel
```
## Password expiration

The default value for the password expiration is 1/1/2099 1:00 AM, you can provide another value like this (in the following example I'm using the CreateVSTSPrincipalOnly paramter set, you can use it with all the calls) : 

```powershell
.\createservicesprincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password "ThePassword" -passwordExpirationDateTime (Get-Date "1/1/2020 1:00 AM")
```