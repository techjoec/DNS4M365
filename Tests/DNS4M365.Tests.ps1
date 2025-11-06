BeforeAll {
    $ModuleName = 'DNS4M365'
    $ModulePath = Join-Path $PSScriptRoot "..\$ModuleName"
    $ManifestPath = Join-Path $ModulePath "$ModuleName.psd1"
}

Describe 'Module Manifest Tests' {
    Context 'Module Manifest Validation' {
        It 'Should have a valid manifest file' {
            $ManifestPath | Should -Exist
        }

        It 'Should have a valid manifest' {
            { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should import without errors' {
            { Import-Module $ManifestPath -Force -ErrorAction Stop } | Should -Not -Throw
        }
    }
}

Describe 'Module Structure Tests' {
    Context 'Module Files' {
        It 'Should have a module file' {
            $ModuleFile = Join-Path $ModulePath "$ModuleName.psm1"
            $ModuleFile | Should -Exist
        }

        It 'Should have Public functions folder' {
            $PublicPath = Join-Path $ModulePath 'Public'
            $PublicPath | Should -Exist
        }

        It 'Should have Private functions folder' {
            $PrivatePath = Join-Path $ModulePath 'Private'
            $PrivatePath | Should -Exist
        }

        It 'Should have at least one Public function' {
            $PublicPath = Join-Path $ModulePath 'Public'
            $PublicFunctions = Get-ChildItem -Path $PublicPath -Filter '*.ps1'
            $PublicFunctions.Count | Should -BeGreaterThan 0
        }
    }
}

Describe 'Module Import Tests' {
    BeforeAll {
        Import-Module $ManifestPath -Force
    }

    Context 'Exported Functions' {
        It 'Should export Compare-M365DnsRecord' {
            Get-Command -Module $ModuleName -Name 'Compare-M365DnsRecord' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Export-M365DomainReport' {
            Get-Command -Module $ModuleName -Name 'Export-M365DomainReport' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export New-M365DmarcRecord' {
            Get-Command -Module $ModuleName -Name 'New-M365DmarcRecord' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Test-M365DnsCompliance' {
            Get-Command -Module $ModuleName -Name 'Test-M365DnsCompliance' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Should export Watch-M365DnsPropagation' {
            Get-Command -Module $ModuleName -Name 'Watch-M365DnsPropagation' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Function Help' {
        BeforeAll {
            $ExportedFunctions = Get-Command -Module $ModuleName
        }

        It 'All exported functions should have help' {
            foreach ($Function in $ExportedFunctions) {
                $Help = Get-Help $Function.Name
                $Help.Description | Should -Not -BeNullOrEmpty
            }
        }

        It 'All exported functions should have examples' {
            foreach ($Function in $ExportedFunctions) {
                $Help = Get-Help $Function.Name
                $Help.Examples | Should -Not -BeNullOrEmpty
            }
        }
    }

    AfterAll {
        Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PSScriptAnalyzer Tests' {
    Context 'PSScriptAnalyzer Standard Rules' {
        BeforeAll {
            if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
                Write-Warning 'PSScriptAnalyzer module not found. Skipping tests.'
                return
            }
            Import-Module PSScriptAnalyzer
        }

        It 'Should pass PSScriptAnalyzer rules' {
            $AnalysisResults = Invoke-ScriptAnalyzer -Path $ModulePath -Recurse -Severity Error
            $AnalysisResults | Should -BeNullOrEmpty
        }
    }
}
