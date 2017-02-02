# vsts-azure-principal

See my [blog post](http://blog.olandese.nl/2017/01/30/a-better-way-and-script-to-add-a-service-principal-in-azure-for-vsts/)

## Parameters Sets examples

### CreateVSTSPrincipalOnly

Create only an Azure AD Application/Principal without any role grant:

```powershell
createvstsprincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password "ThePassword"
```

### CreateVSTSPrincipalWithExistingResourceGroups

Create an Azure AD Application/Principal and grants the Role on the specified existing Resource Groups (if the Resource Groups do not exists no error will be thrown, they will just be ignored):

``` powershell
createvstsprincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password "ThePassword" -resourceGroupNames "ResourceGroupName1","ResourceGroupName2","etc"
```

### CreateVSTSPrincipalAndResourceGroups

Create an Azure AD Application/Principal and the specified Resource Groups at the provided location, grants the Role to the Resource Groups:

``` powershell
createvstsprincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password "ThePassword" -resourceGroupNames "ResourceGroupName1","ResourceGroupName2","etc" -createResourceGroups -location "West Europe"
```

### CreateVSTSPrincipalSubscriptionLevel

Create an Azure AD Application/Principal and grants the Role at subscription level:

``` powershell
createvstsprincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password "ThePassword" -grantRoleOnSubscriptionLevel
```
