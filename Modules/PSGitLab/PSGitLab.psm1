$ConfigurationPath = $Env:AppData
$CommandPath = split-path $PSCommandPath -Parent

Function Save-GitLabAPIConfiguration {
    <#
    .Synopsis
       Used to store information about your GitLab instance. 
    .DESCRIPTION
       Used to store information about your GitLab instance. The domain and api token are given. 
    .EXAMPLE
       Save-GitLabAPIConfiguration -Domain http://gitlab.com -Token "Token"
    .NOTES
       Implemented using Export-CLIXML saving the configurations. Stores .xml in $env:appdata\GitLabAPI\
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,
                   HelpMessage="You can find the token in your profile.",
                   Position=0)]
        [ValidateNotNullOrEmpty()]    
        $Token,

        [Parameter(Mandatory=$true,
                   HelpMessage="Please provide a URI to the GitLab installation",
                   Position=1)]
        [ValidateNotNullOrEmpty()]  
        [ValidatePattern("^(?:http|https):\/\/(?:[\w\.\-\+]+:{0,1}[\w\.\-\+]*@)?(?:[a-z0-9\-\.]+)(?::[0-9]+)?(?:\/|\/(?:[\w#!:\.\?\+=&%@!\-\/\(\)]+)|\?(?:[\w#!:\.\?\+=&%@!\-\/\(\)]+))?$")]  
        $Domain 
    )

        $Parameters = @{
            Token=$Token;
            Domain=$Domain;
        }
        $ConfigPath = "$env:appdata\PSGitLab\PSGitLabConfiguration.xml"
        if (-not (Test-Path (Split-Path $ConfigPath))) {
            New-Item -ItemType Directory -Path (Split-Path $ConfigPath) | Out-Null
        
        }
        $Parameters | Export-Clixml -Path $ConfigPath
}

Function ImportConfig {
    <#
    .Synopsis
       Check for configuration and output the information.
    .DESCRIPTION
       Check for configuration and output the information. Goes into the $env:appdata for the configuration file. 
    .EXAMPLE
        ImportConfig
    #>
    $ConfigFile = "$env:appdata\PSGitLab\PSGitLabConfiguration.xml"
    if (Test-Path $ConfigFile) {
        Import-Clixml $ConfigFile
        
    } else {
        Write-Warning "No Saved Configration Information. Run Save-GitLabAPIConfiguration."
        break;
    }
    
}

Function QueryGitLabAPI {
[cmdletbinding()]
param(
    [Parameter(Mandatory=$true,
               HelpMessage="A hash table used for splatting against invoke-restmethod.",
               Position=0)]
    [ValidateNotNullOrEmpty()]   
    $Request,

    [Parameter(Mandatory=$false,
               HelpMessage="Provide a datatype for the returing objects.",
               Position=1)]
    [ValidateNotNullOrEmpty()]   
    [string]$ObjectType
)

    $GitLabConfig = ImportConfig
    $Domain = $GitLabConfig.Domain
    $Token = $GitLabConfig.Token

    $Headers = @{
        'PRIVATE-TOKEN'=$Token;
    }

    $Request.Add("Headers",$Headers)
    $Request.URI = "$Domain/api/v3" + $Request.URI
    
    try  {
        $Results = Invoke-RestMethod @Request
    } catch {
        $ErrorMessage = $_.exception.response.statusDescription
        Write-Warning  -Message "$ErrorMessage. See $Domain/help/api/README.md#status-codes for more information."
    }

    foreach ($Result in $Results) {
        $Result.pstypenames.insert(0,$ObjectType)
        Write-Output $Result
    }
}

Function Get-GitlabProjects {
[cmdletbinding()]
param(
    [Parameter(Mandatory=$false,
               HelpMessage="Return only archived projects.")]
    [ValidateNotNullOrEmpty()]   
    [switch]$archived = $false,

    [Parameter(Mandatory=$false,
               HelpMessage="Choose how the objects are returned by GitLab.",
               Position=0)]
    [ValidateSet("id","name","path","created_at","updated_at","last_activity_at")]
    [string]$order_by = 'created_at',

    [Parameter(Mandatory=$false,
               HelpMessage="Choose ascending or descending.",
               Position=1)]
    [ValidateSet("asc","desc")]    
    [string]$sort = 'desc',
    
    [Parameter(Mandatory=$false,
               HelpMessage="Search against GitLab to only return certain projects.",
               Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]$search = $null
)

    $Request = @{
        URI="/projects";
        Method='Get';
    }

    ## GET Method Paramters
    $GetUrlParameters = @()
    if ($archived) {
        $GetUrlParameters += @{archived='true'}
    }

    if ($search -ne $null) {
        $GetUrlParameters += @{search=$search}
    }
    $GetUrlParameters += @{order_by=$order_by}
    $GetUrlParameters += @{sort=$sort}
    $URLParamters = GetMethodParameters -GetURLParameters $GetUrlParameters
    $Request.URI = "$($Request.URI)" + "$URLParamters"

    QueryGitLabAPI -Request $Request -ObjectType "GitLab.Project" 
    

}

Function GetMethodParameters {
    [cmdletbinding()]
    param(
        $GetURLParameters
    )

    $string = '?'
    foreach ($Param in $GetUrlParameters) {
        $Param.Keys | ForEach-Object {
            $key = $_
            $value = $Param[$_]
        }
        $string += "&$key=$value"
    }
    $string = $string -replace '\?&',"?"
    Write-Output $string
}

Function Get-GitlabOwnedProjects {
[cmdletbinding()]
param(
    [Parameter(Mandatory=$false,
               HelpMessage="Return only archived projects.")]
    [ValidateNotNullOrEmpty()]   
    [switch]$archived = $false,

    [Parameter(Mandatory=$false,
               HelpMessage="Choose how the objects are returned by GitLab.",
               Position=0)]
    [ValidateSet("id","name","path","created_at","updated_at","last_activity_at")]
    [string]$order_by = 'created_at',

    [Parameter(Mandatory=$false,
               HelpMessage="Choose ascending or descending.",
               Position=1)]
    [ValidateSet("asc","desc")]    
    [string]$sort = 'desc',
    
    [Parameter(Mandatory=$false,
               HelpMessage="Search against GitLab to only return certain projects.",
               Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]$search = $null
)

    $Request = @{
        URI="/projects/owned";
        Method='Get';
    }

    ## GET Method Paramters
    $GetUrlParameters = @()
    if ($archived) {
        $GetUrlParameters += @{archived='true'}
    }

    if ($search -ne $null) {
        $GetUrlParameters += @{search=$search}
    }
    $GetUrlParameters += @{order_by=$order_by}
    $GetUrlParameters += @{sort=$sort}
    $URLParamters = GetMethodParameters -GetURLParameters $GetUrlParameters
    $Request.URI = "$($Request.URI)" + "$URLParamters"

    QueryGitLabAPI -Request $Request -ObjectType "GitLab.Project" 
    

}

Function Get-GitlabAllProjects {
[cmdletbinding()]
param(
    [Parameter(Mandatory=$false,
               HelpMessage="Return only archived projects.")]
    [ValidateNotNullOrEmpty()]   
    [switch]$archived = $false,

    [Parameter(Mandatory=$false,
               HelpMessage="Choose how the objects are returned by GitLab.",
               Position=0)]
    [ValidateSet("id","name","path","created_at","updated_at","last_activity_at")]
    [string]$order_by = 'created_at',

    [Parameter(Mandatory=$false,
               HelpMessage="Choose ascending or descending.",
               Position=1)]
    [ValidateSet("asc","desc")]    
    [string]$sort = 'desc',
    
    [Parameter(Mandatory=$false,
               HelpMessage="Search against GitLab to only return certain projects.",
               Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]$search = $null
)

    $Request = @{
        URI="/projects/all";
        Method='Get';
    }

    ## GET Method Paramters
    $GetUrlParameters = @()
    if ($archived) {
        $GetUrlParameters += @{archived='true'}
    }

    if ($search -ne $null) {
        $GetUrlParameters += @{search=$search}
    }
    $GetUrlParameters += @{order_by=$order_by}
    $GetUrlParameters += @{sort=$sort}
    $URLParamters = GetMethodParameters -GetURLParameters $GetUrlParameters
    $Request.URI = "$($Request.URI)" + "$URLParamters"

    QueryGitLabAPI -Request $Request -ObjectType "GitLab.Project" 
    

}

Function Get-GitlabSingleProject {
[cmdletbinding()]
param(
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [Parameter(ParameterSetName='Id')]
    [string]$Id,

    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [Parameter(ParameterSetName='Namespace')]
    [string]$Namespace
)

    $queryID = $null
    switch ($PSCmdlet.ParameterSetName) {
        'Id' { $queryID = $id }
        'Namespace' { $queryID = $Namespace -replace "/","%2F" -replace " ","" }
    }
    
    $Request = @{
        URI="/projects/$queryID";
        Method='Get';
    }

    QueryGitLabAPI -Request $Request -ObjectType "GitLab.Project" 
    

}

Function Get-GitlabProjectEvents {
[cmdletbinding()]
param(
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [Parameter(ParameterSetName='Id')]
    [string]$Id,

    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [Parameter(ParameterSetName='Namespace')]
    [string]$Namespace
)

    $queryID = $null
    switch ($PSCmdlet.ParameterSetName) {
        'Id' { $queryID = $id }
        'Namespace' { $queryID = $Namespace -replace "/","%2F" -replace " ","" }
    }
    
    $Request = @{
        URI="/projects/$queryID/events";
        Method='Get';
    }

    QueryGitLabAPI -Request $Request -ObjectType "GitLab.Project.Events" 
    

}

Function New-GitLabProject {
    [cmdletbinding()]
    param(
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [string]$Path,
        [string]$Namespace_ID,
        [string]$Description,
        [switch]$Issues_Enabled,
        [switch]$Merge_Requests_Enabled,
        [switch]$Wiki_Enabled,
        [Switch]$Snippets_Enabled,
        [Switch]$public
    )

    $Body = @{
        name=$Name;
    }
  
    $Request = @{
        URI="/projects";
        Method='POST';
        Body=$Body;
    }

    QueryGitLabAPI -Request $Request -ObjectType "GitLab.Project" 

}

Function Remove-GitLabProject {
[cmdletbinding(SupportsShouldProcess=$True,ConfirmImpact="High")]
param(
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)]
    [string]$Id
)

    $Request = @{
        URI="/projects/$ID";
        Method='Delete';
    }

    $Project = Get-GitlabSingleProject -Id $Id

    if ($PSCmdlet.ShouldProcess($Project.Name, "Delete Project")) {
        $Worked = QueryGitLabAPI -Request $Request -ObjectType "GitLab.Project"
    }

    

}