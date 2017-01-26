# CreateVSTSPrincipalWithoutResourceGroup
.\createvstsprincipal.ps1 -subscriptionName "Xpirit - Visual Studio Enterprise with MSDN" -applicationName pasta -password test

# CreateVSTSPrincipalWithExistingResourceGroups
.\createvstsprincipal.ps1 -subscriptionName "Xpirit - Visual Studio Enterprise with MSDN" -applicationName pasta -password test -resourceGroupNames Bestaat,BestaatNIET

# CreateVSTSPrincipalAndResourceGroups
.\createvstsprincipal.ps1 -subscriptionName "Xpirit - Visual Studio Enterprise with MSDN" -applicationName pasta -password test -resourceGroupNames Bestaat,BestaatNIET -createReasourceGroups -location "West Europe"