﻿function Remove-ADOArtifactFeed
{
    <#
    .Synopsis
        Removes artifact feeds from Azure DevOps
    .Description
        Removes artifact feeds from Azure DevOps.  Artifact feeds are used to publish packages.
    .Link
        https://docs.microsoft.com/en-us/rest/api/azure/devops/artifacts/feed%20%20management/create%20feed?view=azure-devops-rest-5.1
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSPossibleIncorrectComparisonWithNull", "", Justification="Explicitly checking for nulls")]
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
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

    # The Feed Name
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidatePattern(
        #?<> -LiteralCharacter '|?/\:&$*"[]>' -CharacterClass Whitespace -Not -Repeat -StartAnchor StringStart -EndAnchor StringEnd
        '\A[^\s\|\?\/\\\:\&\$\*\"\[\]\>]+\z'
    )]
    [string]
    $Name,

    [Parameter(ValueFromPipelineByPropertyName)]
    [Guid]
    $FullyQualifiedID = [Guid]::NewGuid(),

    # The server.  By default https://feeds.dev.azure.com/.
    [Parameter(ValueFromPipelineByPropertyName)]
    [uri]
    $Server = "https://feeds.dev.azure.com/",

    # The api version.  By default, 5.1-preview.
    [string]
    $ApiVersion = "5.1-preview",

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
    }

    process {
        # First, construct a base URI.  It's made up of:
        $uriBase = "$Server".TrimEnd('/'), # * The server
            $Organization, # * The organization
            $(if ($Project) { $project}) -ne $null -join # * an optional project
            '/'

        $specificFeed = $(if ($FullyQualifiedID) { "/$fullyQualifiedID"} elseif ($name) { "/$name"})
        $uri = $uriBase, "_apis/packaging/feeds${specificFeed}?" -join '/' # Next, add on the REST api endpoint


        $uri += @(
            if ($ApiVersion) { # If an -ApiVersion exists, add that to query parameters.
                "api-version=$ApiVersion"
            }
        ) -join '&'


        $invokeParams.Uri = $uri        
        $invokeParams.Method = 'DELETE'

        if ($PSCmdlet.ShouldProcess("$($invokeParams.Method) $($invokeParams.Uri)")) {
            $null = Invoke-ADORestAPI @invokeParams 
        }
    }
}

