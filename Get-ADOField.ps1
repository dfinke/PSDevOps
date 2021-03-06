﻿function Get-ADOField
{
    <#
    .Synopsis
        Gets fields from Azure DevOps
    .Description
        Gets fields from Azure DevOps or Team Foundation Server.
    .Link
        New-ADOField
    .Link
        Remove-ADOField
    .Link
        https://docs.microsoft.com/en-us/rest/api/azure/devops/wit/fields/list?view=azure-devops-rest-5.1
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSPossibleIncorrectComparisonWithNull", "", Justification="Explicitly checking for nulls")]
    param(
    # The Organization
    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
    [Alias('Org')]
    [string]
    $Organization,

    # The Project
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $Project,

    # The server.  By default https://dev.azure.com/.
    # To use against TFS, provide the tfs server URL (e.g. http://tfsserver:8080/tfs).
    [Parameter(ValueFromPipelineByPropertyName)]
    [uri]
    $Server = "https://dev.azure.com/",

    # If set, will force a refresh of the cached results.
    [Alias('Refresh')]
    [switch]
    $Force,

    # The api version.  By default, 5.1.
    # If targeting TFS, this will need to change to match your server version.
    # See: https://docs.microsoft.com/en-us/azure/devops/integrate/concepts/rest-api-versioning?view=azure-devops
    [string]
    $ApiVersion = "5.1",

    # A Personal Access Token
    [Alias('PAT')]
    [string]
    $PersonalAccessToken,

    # Specifies a user account that has permission to send the request. The default is the current user.
    # Type a user name, such as User01 or Domain01\User01, or enter a PSCredential object, such as one generated by the Get-Credential cmdlet.
    [pscredential]
    [Management.Automation.CredentialAttribute()]
    $Credential,

    # Indicates that the cmdlet uses the credentials of the current user to send the web request.
    [Alias('UseDefaultCredential')]
    [switch]
    $UseDefaultCredentials,

    # Specifies that the cmdlet uses a proxy server for the request, rather than connecting directly to the Internet resource. Enter the URI of a network proxy server.
    [uri]
    $Proxy,

    # Specifies a user account that has permission to use the proxy server that is specified by the Proxy parameter. The default is the current user.
    # Type a user name, such as "User01" or "Domain01\User01", or enter a PSCredential object, such as one generated by the Get-Credential cmdlet.
    # This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.
    [pscredential]
    [Management.Automation.CredentialAttribute()]
    $ProxyCredential,

    # Indicates that the cmdlet uses the credentials of the current user to access the proxy server that is specified by the Proxy parameter.
    # This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.
    [switch]
    $ProxyUseDefaultCredentials
    )

    begin {
        #region Copy Invoke-ADORestAPI parameters
        # Because this command wraps Invoke-ADORestAPI, we want to copy over all shared parameters.
        $invokeRestApi = # To do this, first we get the commandmetadata for Invoke-ADORestAPI.
            [Management.Automation.CommandMetaData]$ExecutionContext.SessionState.InvokeCommand.GetCommand('Invoke-ADORestAPI', 'Function')

        $invokeParams = @{} + $PSBoundParameters # Then we copy our parameters
        foreach ($k in @($invokeParams.Keys)) {  # and walk thru each parameter name.
            # If a parameter isn't found in Invoke-ADORestAPI
            if (-not $invokeRestApi.Parameters.ContainsKey($k)) {
                $invokeParams.Remove($k) # we remove it.
            }
        }
        # We're left with a hashtable containing only the parameters shared with Invoke-ADORestAPI.
        #endregion Copy Invoke-ADORestAPI parameters

        # Because fields don't change often,
        if (-not $Script:ADOFieldCache) { # if we haven't already created a cache
            $Script:ADOFieldCache = @{} # create a cache.
        }
    }

    process {
        # First, construct a base URI.  It's made up of:
        $uriBase = "$Server".TrimEnd('/'), # * The server
            $Organization, # * The organization
            $(if ($Project) { $project}) -ne $null -join
            '/'

        $uri = $uriBase, "_apis/wit/fields?" -join '/' # Next, add on the REST api endpoint
        if ($ApiVersion) { # If an -ApiVersion exists, add that to query parameters.
            $uri += "api-version=$ApiVersion"
        }
        $invokeParams.Uri = $uri

        if ($Force) { # If we're forcing a refresh
            $Script:ADOFieldCache.Remove($uriBase) # clear the cached results for $uriBase.
        }


        if (-not $Script:ADOFieldCache.$uriBase) { # If we have nothing cached,
            $typenames = @( # Prepare a list of typenames so we can customize formatting:
                if ($Organization -and $Project) {
                    "$Organization.$Project.Field" # * $Organization.$Project.Field (if $product exists)
                }
                "$Organization.Field" # * $Organization.Field
                'PSDevOps.Field' # * PSDevOps.Field
            )

            Write-Verbose "Caching ADO Fields for $uriBase"

            # Invoke the REST api
            $Script:ADOFieldCache.$uriBase =
                Invoke-ADORestAPI @invokeParams -PSTypeName $typenames # decorate results with the Typenames,
            # and cache the result.
        }


        $Script:ADOFieldCache.$uriBase # Last but not least, output what was in the cache.
    }
}