﻿#Requires -Modules Pester
#Requires -Modules @{ModuleName = 'Assert' ; ModuleVersion = '0.9.2.1'}

$Verbose = @{Verbose = $false}
#$Verbose = @{Verbose = $true}

if ($PSScriptRoot)
{
    $ScriptRoot = $PSScriptRoot
}
elseif ($psISE.CurrentFile.IsUntitled -eq $false)
{
    $ScriptRoot = Split-Path -Path $psISE.CurrentFile.FullPath
}
elseif ($null -ne $psEditor.GetEditorContext().CurrentFile.Path -and $psEditor.GetEditorContext().CurrentFile.Path -notlike 'untitled:*')
{
    $ScriptRoot = Split-Path -Path $psEditor.GetEditorContext().CurrentFile.Path
}
else
{
    $ScriptRoot = '.'
}

$TestDataSetSmall = {
    $PSCustomObjects = @(
        [PSCustomObject]@{ID = 1 ; Sub = 'S1' ; IntO = 6}
        [PSCustomObject]@{ID = 2 ; Sub = 'S2' ; IntO = 7}
        [PSCustomObject]@{ID = 3 ; Sub = 'S3' ; IntO = $null}
    )

    $DataTable = [Data.DataTable]::new('Test')
    $null = $DataTable.Columns.Add('IDD', [System.Int32])
    $null = $DataTable.Columns.Add('Name')
    $null = $DataTable.Columns.Add('Junk')
    $null = $DataTable.Columns.Add('IntT', [System.Int32])
    $null = $DataTable.Rows.Add(1, 'A', 'AAA', 5)
    $null = $DataTable.Rows.Add(3, 'C', 'S3', $null)
    $null = $DataTable.Rows.Add(4, 'D', $null, $null)
}
#. $TestDataSetSmall

function Format-Test
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [HashTable]$Test
    )
    if ($TestDataSetName, $Test.Params.Left, $Test.Params.Right, $Test.Description -contains $null)
    {
        Throw 'Missing param'
    }

    $Test.TestName = '{0}, {3}. {1} - {2}' -f $TestDataSetName, $Test.Params.Left, $Test.Params.Right, $Test.Description
    $Test.TestDataSet = Get-Variable -Name $TestDataSetName -ValueOnly
    $Test
}

function Get-Params
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String]$Param
    )
    $ParamSplit = $Param -split '(?=\[)'
    $Output = (Get-Variable -Name $ParamSplit[0]).Value
    if ($null -ne $ParamSplit[1])
    {
        , $Output.Item($ParamSplit[1].Trim('[]'))
    }
    else
    {
        , $Output
    }
}

Describe -Name 'Join-Object' -Fixture {
    $TestDataSetName = 'TestDataSetSmall'
    Context -Name $TestDataSetName -Fixture {
        It -name "Testing <TestName>" -TestCases @(
            Format-Test @{
                Description          = 'Default Error'
                ExpectedErrorOn      = 'Test'
                ExpectedErrorMessage = "but some values were missing: 'PSObject{ID=3; R_IntT=; R_Name=X; Subscription=S3}"
                Params               = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description          = 'DataTable Error'
                ExpectedErrorOn      = 'Test'
                ExpectedErrorMessage = "but some values were missing: 'psobject{IDD=3; IntT=; Junk=S3; Name=X; R_IntO=; R_Sub=S3}"
                Params               = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                }
            }

            Format-Test @{
                Description = 'Default'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description = 'Default'
                Params      = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObjects'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    RightProperties       = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                }
            }
            Format-Test @{
                Description = 'Default AllInBoth' # TODO: Enhancement. Replace LeftJoinProperty with MoreLinq Key?
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    Type                   = 'AllInBoth'
                }
            }
            Format-Test @{
                Description = 'Default AllInBoth'
                Params      = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObjects'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    RightProperties       = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                    Type                  = 'AllInBoth'
                }
            }
            Format-Test @{
                Description = 'Default OnlyIfInBoth'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    Type                   = 'OnlyIfInBoth'
                }
            }
            Format-Test @{
                Description = 'Default OnlyIfInBoth'
                Params      = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObjects'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    RightProperties       = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                    Type                  = 'OnlyIfInBoth'
                }
            }

            Format-Test @{
                Description = 'PassThru'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    PassThru               = $true
                }
            }
            Format-Test @{
                Description = 'PassThru'
                Params      = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObjects'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    LeftProperties        = @{IDD = 'IDD' ; Name = 'NewName'}
                    RightProperties       = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                    PassThru              = $true
                }
            }
            Format-Test @{
                Description          = 'PassThru AllInBoth'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = '"-PassThru" and "-Type AllInBoth" are not compatible'
                Params               = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    PassThru               = $true
                    Type                   = 'AllInBoth'
                }
            }
            Format-Test @{
                Description          = 'PassThru AllInBoth'
                ExpectedErrorOn      = 'Run'
                ExpectedErrorMessage = '"-PassThru" and "-Type AllInBoth" are not compatible'
                Params               = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObjects'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    LeftProperties        = @{IDD = 'IDD' ; Name = 'NewName'}
                    RightProperties       = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                    PassThru              = $true
                    Type                  = 'AllInBoth'
                }
            }
            Format-Test @{
                Description = 'PassThru OnlyIfInBoth'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    PassThru               = $true
                    Type                   = 'OnlyIfInBoth'
                }
            }
            Format-Test @{
                Description = 'PassThru OnlyIfInBoth'
                Params      = @{
                    Left                  = 'DataTable'
                    Right                 = 'PSCustomObjects'
                    LeftJoinProperty      = 'IDD'
                    RightJoinProperty     = 'ID'
                    LeftProperties        = @{IDD = 'IDD' ; Name = 'NewName'}
                    RightProperties       = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeLeftProperties = 'Junk'
                    Suffix                = '_R'
                    PassThru              = $true
                    Type                  = 'OnlyIfInBoth'
                }
            }

            Format-Test @{
                Description = 'DataTable'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                }
            }
            Format-Test @{
                Description = 'DataTable'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                }
            }
            Format-Test @{
                Description = 'DataTable AllInBoth'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInBoth'
                }
            }
            Format-Test @{
                Description = 'DataTable AllInBoth'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'AllInBoth'
                }
            }
            Format-Test @{
                Description = 'DataTable OnlyIfInBoth'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'OnlyIfInBoth'
                }
            }
            Format-Test @{
                Description = 'DataTable OnlyIfInBoth'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    Type                   = 'OnlyIfInBoth'
                }
            }

            Format-Test @{
                Description = 'Default Ordered'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = [ordered]@{Sub = 'Subscription' ; ID = 'ID'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description = 'Default DBNull to $null'
                Params      = @{
                    Left              = 'PSCustomObjects'
                    Right             = 'DataTable'
                    LeftJoinProperty  = 'ID'
                    RightJoinProperty = 'IDD'
                }
            }
            Format-Test @{
                Description = 'Default Single'
                Params      = @{
                    Left                   = 'PSCustomObjects[0]'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description = 'Default KeepRightJoinProperty'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    KeepRightJoinProperty  = $true
                }
            }
            Format-Test @{
                Description = 'Default Multi Join'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'ID', 'Sub'
                    RightJoinProperty      = 'IDD', 'Junk'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                }
            }
            Format-Test @{
                Description = 'Default JoinScript'
                Params      = @{
                    Left                   = 'PSCustomObjects'
                    Right                  = 'DataTable'
                    LeftJoinProperty       = 'Sub'
                    RightJoinProperty      = 'IDD'
                    LeftProperties         = @{ID = 'ID' ; Sub = 'Subscription'}
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    LeftJoinScript         = {param ($Line) ($Line.$LeftJoinProperty).Replace('S', 'X')}
                    RightJoinScript        = {param ($Line) 'X' + ($Line.$RightJoinProperty)}
                }
            }
            Format-Test @{
                Description = 'DataTable DataTableTypes'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    DataTable              = $true
                    DataTableTypes         = @{R_IntO = [Int]}
                }
            }
            Format-Test @{
                Description = 'PassThru DataTableTypes'
                Params      = @{
                    Left                   = 'DataTable'
                    Right                  = 'PSCustomObjects'
                    LeftJoinProperty       = 'IDD'
                    RightJoinProperty      = 'ID'
                    ExcludeRightProperties = 'Junk'
                    Prefix                 = 'R_'
                    PassThru              = $true
                    DataTableTypes         = @{R_IntO = [Int]}
                }
            }
        ) -test {
            param (
                $Params,
                $TestDataSet,
                $TestName,
                $Description,
                $RunScript,
                $ExpectedErrorMessage,
                [validateset('Test', 'Run')]
                $ExpectedErrorOn
            )
            #if ($TestName -notlike '*Default Multi Join*') {Continue}

            # Load Data
            . $TestDataSet
            if ($RunScript)
            {
                . $RunScript
            }
            $Params.Left = Get-Params -Param $Params.Left
            $Params.Right = Get-Params -Param $Params.Right

            # Save Before Data Copy
            $BeforeLeft = [System.Management.Automation.PSSerializer]::Deserialize([System.Management.Automation.PSSerializer]::Serialize($Params.Left, 2))
            $BeforeRight = [System.Management.Automation.PSSerializer]::Deserialize([System.Management.Automation.PSSerializer]::Serialize($Params.Right, 2))

            # Execute Cmdlet
            if ($ExpectedErrorOn -eq 'Run')
            {
                {$JoinedOutput = Join-Object @Params} | Should -Throw -ExpectedMessage $ExpectedErrorMessage
                Continue
            }
            else
            {
                $JoinedOutput = Join-Object @Params
            }
            Write-Verbose ('it returns:' + ($JoinedOutput | Format-Table | Out-String)) @Verbose

            <# Save CompareData (Xml)
            Write-Host ($TestName + ($JoinedOutput | Format-Table | Out-String))
            Export-Clixml -LiteralPath "$ScriptRoot\CompareData\$TestName.xml" -InputObject $JoinedOutput
            #>

            # Get CompareData
            $CompareDataXml = (Get-Content -LiteralPath "$ScriptRoot\CompareData\$TestName.xml") -join [Environment]::NewLine
            $CompareDataNew = [System.Management.Automation.PSSerializer]::Deserialize($CompareDataXml)
            Write-Verbose ('it should return:' + ($CompareDataNew | Format-Table | Out-String)) @Verbose

            # Test
            if ($ExpectedErrorOn -eq 'Test')
            {
                {Assert-Equivalent -Actual $JoinedOutput -Expected $CompareDataNew -StrictOrder -StrictType} | Should -Throw -ExpectedMessage $ExpectedErrorMessage
            }
            else
            {
                Assert-Equivalent -Actual $JoinedOutput -Expected $CompareDataNew -StrictOrder -StrictType
            }

            if ($Params.PassThru)
            {
                Assert-Equivalent -Actual $Params.Left -Expected $CompareDataNew -StrictOrder -StrictType
            }
            else
            {
                Assert-Equivalent -Actual $Params.Left -Expected $BeforeLeft -StrictOrder -StrictType
            }
            Assert-Equivalent -Actual $Params.Right -Expected $BeforeRight -StrictOrder -StrictType

            if (!$Params.PassThru)
            {
                if ($Params.DataTable)
                {
                    Should -BeOfType -ActualValue $JoinedOutput -ExpectedType 'System.Data.DataTable'
                    $JoinedOutput | Should -BeOfType -ExpectedType 'System.Data.DataRow'
                }
                else
                {
                    if ($JoinedOutput.Count -gt 0)
                    {
                        Should -BeOfType -ActualValue $JoinedOutput -ExpectedType 'System.Array'
                    }
                    else
                    {
                        Should -BeOfType -ActualValue $JoinedOutput -ExpectedType 'PSCustomObject'
                    }
                    $JoinedOutput | Should -BeOfType -ExpectedType 'PSCustomObject'
                }
            }
        }
    }
}