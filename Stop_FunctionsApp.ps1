Param(
    $ARM_SUBSCRIPTION_ID = "",
    $ARM_TENANT_ID = "",
    $ARM_CLIENT_ID = "",
    $ARM_CLIENT_SECRET = "",
    $FunctionConfigurations = @{
        "RG1" = @("Function1", "Function2");
        "RG2" = @("Function1");
        "RG3" = @("Function1", "Function2", "Function3")
    }
)

function authAzure {
    $SecureStringPwd = $ARM_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
    $pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ARM_CLIENT_ID, $SecureStringPwd
    Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $ARM_TENANT_ID
    Set-AzContext -SubscriptionId $ARM_SUBSCRIPTION_ID
    StopFunctions $FunctionConfigurations
}

function StopFunctions($FunctionConfigurations) {
    foreach ($resourceGroup in $FunctionConfigurations.Keys) {
        $functions = $FunctionConfigurations[$resourceGroup]
        $resourceGroupName = $resourceGroup

        foreach ($functionName in $functions) {
            $function = Get-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionName

            if (!$function) {
                Write-Output "Azure Function $functionName not found in resource group $resourceGroupName"
                continue
            }

            if ($function.State -eq "Stopped") {
                Write-Output "Azure Function $functionName is already stopped"
            }
            else {
                Stop-AzFunctionApp -ResourceGroupName $resourceGroupName -Name $functionName -Force
                Write-Output "Stopped Azure Function $functionName in resource group $resourceGroupName"
            }
        }
    }
}

authAzure