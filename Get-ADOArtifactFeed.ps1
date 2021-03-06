﻿function Get-ADOArtifactFeed
{
    <#
    .Synopsis
        Gets artifact feeds from Azure DevOps
    .Description
        Gets artifact feeds from Azure DevOps.  Artifact feeds can be used to publish packages.
    .Link
        https://docs.microsoft.com/en-us/rest/api/azure/devops/artifacts/feed%20%20management/get%20feeds?view=azure-devops-rest-5.1
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSPossibleIncorrectComparisonWithNull", "", Justification="Explicitly checking for nulls")]
    [CmdletBinding(DefaultParameterSetName='packaging/Feeds/{FeedId}')]
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

    # The name or ID of the feed.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('fullyQualifiedId')]
    [string]
    $FeedID,

    # If set, will Get Artifact Feed Views
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/Feeds/{feedID}/views')]
    [Alias('Views')]
    [switch]
    $View,

    # If set, will get artifact permissions
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/Feeds/{feedID}/permissions')]
    [Alias('Permissions')]
    [switch]
    $Permission,

    # If set, will get artifact retention policies
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/Feeds/{feedID}/retentionpolicies')]
    [Alias('RetentionPolicies')]
    [switch]
    $RetentionPolicy,

    # If set, will get information about a Node Package Manager module.
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/npm/{packageName}/versions/{packageVersion}')]
    [Alias('NodePackageManager')]
    [switch]
    $NPM,

    # If set, will get information about a Nuget module.
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/nuget/packages/{packageName}/versions/{packageVersion}')]
    [switch]
    $NuGet,

    # If set, will get information about a Python module.
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/pypi/packages/{packageName}/versions/{packageVersion}')]
    [Alias('PyPi')]
    [switch]
    $Python,

    # If set, will get information about a Universal package module.
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/upack/packages/{packageName}/versions/{packageVersion}')]
    [Alias('UPack')]
    [switch]
    $Universal,

    # The Package Name.  Must be used with -NPM, -NuGet, -Python, or -Universal.
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/upack/packages/{packageName}/versions/{packageVersion}')]
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/npm/{packageName}/versions/{packageVersion}')]
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/nuget/packages/{packageName}/versions/{packageVersion}')]
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/pypi/packages/{packageName}/versions/{packageVersion}')]
    [string]
    $PackageName,

    # The Package Version.  Must be used with -NPM, -NuGet, -Python, or -Universal.
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/upack/packages/{packageName}/versions/{packageVersion}')]
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/npm/{packageName}/versions/{packageVersion}')]
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/nuget/packages/{packageName}/versions/{packageVersion}')]
    [Parameter(Mandatory,ValueFromPipelineByPropertyName,ParameterSetName='packaging/feeds/{feedId}/pypi/packages/{packageName}/versions/{packageVersion}')]
    [string]
    $PackageVersion,

    # The Feed Role
    [Parameter(ValueFromPipelineByPropertyName,ParameterSetName='packaging/Feeds')]
    [ValidateSet('Administrator','Collaborator', 'Contributor','Reader')]
    [string]
    $FeedRole,

    # If set, will include deleted feeds.
    [switch]
    $IncludeDeleted,

    [Alias('Changes')]
    [switch]
    $Change,

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

        $subTypeName = ''
        if ($Change) { # If we're looking for changes,
            $subtypeName = '.Change'
            if (-not $FeedID) { # but haven't specified feed
                $uri = $uriBase, "_apis/packaging/feedchanges?" -join '/'
            } elseif ($Change) {
                $uri = $uriBase, "_apis/packaging/feeds/$FeedID", 'packagechanges?' -join '/'
            }
        } elseif (-not $Change) {
            $uriParameters = [Regex]::Replace($PSCmdlet.ParameterSetName, '/\{(?<Variable>\w+)\}', {param($match)
                $var = $ExecutionContext.SessionState.PSVariable.Get($match.Groups['Variable'].ToString())
                if ($null -ne $var.Value) {
                    return '/' + ($var.Value.ToString())
                } else {
                    return ''
                }
            }, 'IgnoreCase,IgnorePatternWhitespace')

            $uri = $uriBase, '_apis', $uriParameters -join '/' # Next, add on the REST api endpoint
            $uri += '?'
        }

        foreach ($typeSwitch in 'View', 'Permission', 'RetentionPolicy', 'NPM', 'Nuget','Python', 'Universal') {
            if ($PSBoundParameters.$typeSwitch -and -not $FeedID) {
                $splat = @{} + $PSBoundParameters
                $splat.Remove($typeSwitch)
                $splat2 =
                if ('NPM', 'NuGet', 'Python', 'Universal' -contains $typeSwitch) {
                    $splat.Remove('PackageName')
                    $splat.Remove('PackageVersion')
                    $splat + @{$typeSwitch=$true;PackageName=$PackageName;PackageVersion=$PackageVersion}
                } else {
                    $splat + @{$typeSwitch=$true}
                }

                Get-ADOArtifactFeed @splat |
                    & { process {
                        $feedID = $_.FullyQualifiedID
                        $_ | Get-ADOArtifactFeed @splat2 |
                        Add-Member NoteProperty FeedID $feedID -Force -PassThru
                    } }
                return
            } elseif ($PSBoundParameters.$typeSwitch) {
                $subtypeName = ".$typeSwitch"
            }
        }

        $uri += @(
            if ($FeedRole) { "feedRole=$($FeedRole.ToLower())" }
            if ($IncludeDeleted) { "includeDeletedUpstreams=true" }
            if ($ApiVersion) { "api-version=$ApiVersion" }
        ) -join '&'

        $invokeParams.Uri = $uri

        $typenames = @( # Prepare a list of typenames so we can customize formatting:
            if ($Organization -and $Project) {
                "$Organization.$Project.ArtifactFeed$subtypeName" # * $Organization.$Project.ArtifactFeed (if $product exists)
            }
            "$Organization.ArtifactFeed$subtypeName" # * $Organization.ArtifactFeed
            "PSDevOps.ArtifactFeed$subtypeName" # * PSDevOps.ArtifactFeed
        )

        $additionalProperty = @{Organization=$Organization}
        if ($Project) { $additionalProperty['Project'] = $Project }
        $invokeParams.Property = $additionalProperty
        if (-not $subTypeName) {
            $invokeParams.RemoveProperty = 'ViewID','ViewName'
        } else {
            $invokeParams.Property["FeedID"] = $FeedID
        }


        # Invoke the REST api
        Invoke-ADORestAPI @invokeParams -PSTypeName $typenames # decorate results with the Typenames.
    }
}
