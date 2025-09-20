# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

using namespace System.Collections
using namespace System.Management.Automation
using namespace System.Reflection
using namespace System.Threading
using namespace System.Threading.Tasks

function Start-DebugAttachSession {
    <#
    .EXTERNALHELP ..\PowerShellEditorServices.Commands-help.xml
    #>
    [OutputType([System.Management.Automation.Job2])]
    [CmdletBinding(DefaultParameterSetName = 'ProcessId')]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'ProcessId')]
        [int]
        $ProcessId,

        [Parameter(ParameterSetName = 'CustomPipeName')]
        [string]
        $CustomPipeName,

        [Parameter()]
        [string]
        $RunspaceName,

        [Parameter()]
        [int]
        $RunspaceId,

        [Parameter()]
        [string]
        $ComputerName,

        [Parameter()]
        [ValidateSet('Close', 'Hide', 'Keep')]
        [string]
        $WindowActionOnEnd,

        [Parameter()]
        [IDictionary[]]
        $PathMapping,

        [Parameter()]
        [switch]
        $AsJob
    )

    $ErrorActionPreference = 'Stop'

    try {
        if ($PSBoundParameters.ContainsKey('RunspaceId') -and $RunspaceName) {
            $err = [ErrorRecord]::new(
                [ArgumentException]::new("Cannot specify both RunspaceId and RunspaceName parameters"),
                "InvalidRunspaceParameters",
                [ErrorCategory]::InvalidArgument,
                $null)
            $err.ErrorDetails = [ErrorDetails]::new("")
            $err.ErrorDetails.RecommendedAction = 'Specify only one of RunspaceId or RunspaceName.'
            $PSCmdlet.WriteError($err)
            return
        }

        # Var will be set by PSES in configurationDone before launching script
        $debugServer = Get-Variable -Name __psEditorServices_DebugServer -ValueOnly -ErrorAction Ignore
        if (-not $debugServer) {
            $err = [ErrorRecord]::new(
                [Exception]::new("Cannot start a new attach debug session unless running in an existing launch debug session not in a temporary console"),
                "NoDebugSession",
                [ErrorCategory]::InvalidOperation,
                $null)
            $err.ErrorDetails = [ErrorDetails]::new("")
            $err.ErrorDetails.RecommendedAction = 'Launch script with debugging to ensure the debug session is available.'
            $PSCmdlet.WriteError($err)
            return
        }

        if ($AsJob -and -not (Get-Command -Name Start-ThreadJob -ErrorAction Ignore)) {
            $err = [ErrorRecord]::new(
                [Exception]::new("Cannot use the -AsJob parameter unless running on PowerShell 7+ or the ThreadJob module is present"),
                "NoThreadJob",
                [ErrorCategory]::InvalidArgument,
                $null)
            $err.ErrorDetails = [ErrorDetails]::new("")
            $err.ErrorDetails.RecommendedAction = 'Install the ThreadJob module or run on PowerShell 7+.'
            $PSCmdlet.WriteError($err)
            return
        }

        $configuration = @{
            type = 'PowerShell'
            request = 'attach'
            # A temp console is also needed as the current one is busy running
            # this code. Failing to set this will cause a deadlock.
            createTemporaryIntegratedConsole = $true
        }

        if ($ProcessId) {
            if ($ProcessId -eq $PID) {
                $err = [ErrorRecord]::new(
                    [ArgumentException]::new("PSES does not support attaching to the current editor process"),
                    "AttachToCurrentProcess",
                    [ErrorCategory]::InvalidArgument,
                    $PID)
                $err.ErrorDetails = [ErrorDetails]::new("")
                $err.ErrorDetails.RecommendedAction = 'Specify a different process id.'
                $PSCmdlet.WriteError($err)
                return
            }

            if ($Name) {
                $configuration.name = $Name
            }
            else {
                $configuration.name = "Attach Process $ProcessId"
            }
            $configuration.processId = $ProcessId
        }
        elseif ($CustomPipeName) {
            if ($Name) {
                $configuration.name = $Name
            }
            else {
                $configuration.name = "Attach Pipe $CustomPipeName"
            }
            $configuration.customPipeName = $CustomPipeName
        }
        else {
            $configuration.name = 'Attach Session'
        }

        if ($ComputerName) {
            $configuration.computerName = $ComputerName
        }

        if ($PSBoundParameters.ContainsKey('RunspaceId')) {
            $configuration.runspaceId = $RunspaceId
        }
        elseif ($RunspaceName) {
            $configuration.runspaceName = $RunspaceName
        }

        if ($WindowActionOnEnd) {
            $configuration.temporaryConsoleWindowActionOnDebugEnd = $WindowActionOnEnd.ToLowerInvariant()
        }

        if ($PathMapping) {
            $configuration.pathMappings = $PathMapping
        }

        # https://microsoft.github.io/debug-adapter-protocol/specification#Reverse_Requests_StartDebugging
        $resp = $debugServer.SendRequest(
            'startDebugging',
            @{
                configuration = $configuration
                request = 'attach'
            }
        )

        # PipelineStopToken added in pwsh 7.6
        $cancelToken = if ($PSCmdlet.PipelineStopToken) {
            $PSCmdlet.PipelineStopToken
        }
        else {
            [CancellationToken]::new($false)
        }

        # There is no response for a startDebugging request
        $task = $resp.ReturningVoid($cancelToken)

        $waitTask = {
            [CmdletBinding()]
            param ([Parameter(Mandatory)][Task]$Task)

            while (-not $Task.AsyncWaitHandle.WaitOne(300)) {}
            $null = $Task.GetAwaiter().GetResult()
        }

        if ($AsJob) {
            # Using the Ast to build the scriptblock allows the job to inherit
            # the using namespace entries and include the proper line/script
            # paths in any error traces that are emitted.
            Start-ThreadJob -ScriptBlock {
                & ($args[0]).Ast.GetScriptBlock() $args[1]
            } -ArgumentList $waitTask, $task
        }
        else {
            & $waitTask $task
        }
    }
    catch {
        $PSCmdlet.WriteError($_)
        return
    }
}
# SIG # Begin signature block
# MIIoLAYJKoZIhvcNAQcCoIIoHTCCKBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDdZ9zGYaknA4wm
# 1HANP/bBuZfAEEn3kdJuU1CEZ+7qdaCCDXYwggX0MIID3KADAgECAhMzAAAEhV6Z
# 7A5ZL83XAAAAAASFMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjUwNjE5MTgyMTM3WhcNMjYwNjE3MTgyMTM3WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDASkh1cpvuUqfbqxele7LCSHEamVNBfFE4uY1FkGsAdUF/vnjpE1dnAD9vMOqy
# 5ZO49ILhP4jiP/P2Pn9ao+5TDtKmcQ+pZdzbG7t43yRXJC3nXvTGQroodPi9USQi
# 9rI+0gwuXRKBII7L+k3kMkKLmFrsWUjzgXVCLYa6ZH7BCALAcJWZTwWPoiT4HpqQ
# hJcYLB7pfetAVCeBEVZD8itKQ6QA5/LQR+9X6dlSj4Vxta4JnpxvgSrkjXCz+tlJ
# 67ABZ551lw23RWU1uyfgCfEFhBfiyPR2WSjskPl9ap6qrf8fNQ1sGYun2p4JdXxe
# UAKf1hVa/3TQXjvPTiRXCnJPAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUuCZyGiCuLYE0aU7j5TFqY05kko0w
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwNTM1OTAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBACjmqAp2Ci4sTHZci+qk
# tEAKsFk5HNVGKyWR2rFGXsd7cggZ04H5U4SV0fAL6fOE9dLvt4I7HBHLhpGdE5Uj
# Ly4NxLTG2bDAkeAVmxmd2uKWVGKym1aarDxXfv3GCN4mRX+Pn4c+py3S/6Kkt5eS
# DAIIsrzKw3Kh2SW1hCwXX/k1v4b+NH1Fjl+i/xPJspXCFuZB4aC5FLT5fgbRKqns
# WeAdn8DsrYQhT3QXLt6Nv3/dMzv7G/Cdpbdcoul8FYl+t3dmXM+SIClC3l2ae0wO
# lNrQ42yQEycuPU5OoqLT85jsZ7+4CaScfFINlO7l7Y7r/xauqHbSPQ1r3oIC+e71
# 5s2G3ClZa3y99aYx2lnXYe1srcrIx8NAXTViiypXVn9ZGmEkfNcfDiqGQwkml5z9
# nm3pWiBZ69adaBBbAFEjyJG4y0a76bel/4sDCVvaZzLM3TFbxVO9BQrjZRtbJZbk
# C3XArpLqZSfx53SuYdddxPX8pvcqFuEu8wcUeD05t9xNbJ4TtdAECJlEi0vvBxlm
# M5tzFXy2qZeqPMXHSQYqPgZ9jvScZ6NwznFD0+33kbzyhOSz/WuGbAu4cHZG8gKn
# lQVT4uA2Diex9DMs2WHiokNknYlLoUeWXW1QrJLpqO82TLyKTbBM/oZHAdIc0kzo
# STro9b3+vjn2809D0+SOOCVZMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGgwwghoIAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAASFXpnsDlkvzdcAAAAABIUwDQYJYIZIAWUDBAIB
# BQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF67cQS99mCILNc5BcCNfW3V
# 7RK2J4XhfL2ENG3xq3cSMEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEB
# BQAEggEAm1X7oZiY4COYfkOpWh+THHX8mDZAjcAi4EUzGzonEciQ/LMXvs0xYuEi
# p7/0u6+I1q5zDW9YuAPYzob6+CKcAgO/xT2U9m29NWGhUL4dsRdo82FE02Zet3cB
# 0g+EgLtWmTDBdoLsgBDAgnlADpmmrk9FVo+PB2V8hHx4zpperSYH/wiM1cXOpa6K
# TarzeOobxP/tnemAfajj8WXXQehAZAvh7WQEaZcqiBEc1lMmfGYvtjgxfwaHHHnf
# O7+1nCiXi8A5VBZta7+e/Ic3CFdzA6G9OLkuW//03/rlp+kXqINysT6YbBrfW5+8
# nET4b+Q+mN9S05/bZNEzn1nC4JTOC6GCF5YwgheSBgorBgEEAYI3AwMBMYIXgjCC
# F34GCSqGSIb3DQEHAqCCF28wghdrAgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFRBgsq
# hkiG9w0BCRABBKCCAUAEggE8MIIBOAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFl
# AwQCAQUABCCBF3Y7My76KDVPTNIZ0S6Y9aU1JI7l5MMHQ8SfI/o2OAIGaKOepZEQ
# GBIyMDI1MDkwNTIxMDUwMS45N1owBIACAfSggdGkgc4wgcsxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVy
# aWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpEQzAwLTA1
# RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaCC
# Ee0wggcgMIIFCKADAgECAhMzAAACA7seXAA4bHTKAAEAAAIDMA0GCSqGSIb3DQEB
# CwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
# EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNV
# BAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTI1MDEzMDE5NDI0
# NloXDTI2MDQyMjE5NDI0NlowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMx
# JzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjpEQzAwLTA1RTAtRDk0NzElMCMGA1UE
# AxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAKGXQwfnACc7HxSHxG2J0XQnTJoUMclgdOk+9FHXpfUr
# EYNh9Pw+twaMIsKJo67crUOZQhThFzmiWd2Nqmk246DPBSiPjdVtsnHk8VNj9rVn
# zS2mpU/Q6gomVSR8M9IEsWBdaPpWBrJEIg20uxRqzLTDmDKwPsgs9m6JCNpx7krE
# BKMp/YxVfWp8TNgFtMY0SKNJAIrDDJzR5q+vgWjdf/6wK64C2RNaKyxTriTysrrS
# OwZECmIRJ1+4evTJYCZzuNM4814YDHooIvaS2mcZ6AsN3UiUToG7oFLAAgUevvM7
# AiUWrJC4J7RJAAsJsmGxP3L2LLrVEkBexTS7RMLlhiZNJsQjuDXR1jHxSP6+H0ic
# ugpgLkOkpvfXVthV3RvK1vOV9NGyVFMmCi2d8IAgYwuoSqT3/ZVEa72SUmLWP2dV
# +rJgdisw84FdytBhbSOYo2M4vjsJoQCs3OEMGJrXBd0kA0qoy8nylB7abz9yJvIM
# z7UFVmq40Ci/03i0kXgAK2NfSONc0NQy1JmhUVAf4WRZ189bHW4EiRz3tH7FEu4+
# NTKkdnkDcAAtKR7hNpEG9u9MFjJbYd6c5PudgspM7iPDlCrpzDdn3NMpI9DoPmXK
# Jil6zlFHYx0y8lLh8Jw8kV5pU6+5YVJD8Qa1UFKGGYsH7l7DMXN2l/VS4ma45BNP
# AgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUsilZQH4R55Db2xZ7RV3PFZAYkn0wHwYD
# VR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZO
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIw
# VGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBc
# BggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0
# cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYD
# VR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8EBAMC
# B4AwDQYJKoZIhvcNAQELBQADggIBAJAQxt6wPpMLTxHShgJ1ILjnYBCsZ/87z0ZD
# ngK2ASxvHPAYNVRyaNcVydolJM150EpVeQGBrBGic/UuDEfhvPNWPZ5Y2bMYjA7U
# WWGV0A84cDMsEQdGhJnil10W1pDGhptT83W9bIgKI3rQi3zmCcXkkPgwxfJ3qlLx
# 4AMiLpO2N+Ao+i6ZZrQEVD9oTONSt883Wvtysr6qSYvO3D8Q1LvN6Z/LHiQZGDBj
# VYF8Wqb+cWUkM9AGJyp5Td06n2GPtaoPRFz7/hVnrBCN6wjIKS/m6FQ3LYuE0OLa
# V5i0CIgWmaN82TgaeAu8LZOP0is4y/bRKvKbkn8WHvJYCI94azfIDdBqmNlO1+vs
# 1/OkEglDjFP+JzhYZaqEaVGVUEjm7o6PDdnFJkIuDe9ELgpjKmSHwV0hagqKuOJ0
# QaVew06j5Q/9gbkqF5uK51MHEZ5x8kK65Sykh1GFK0cBCyO/90CpYEuWGiurY4Jo
# /7AWETdY+CefHml+W+W6Ohw+Cw3bj7510euXc7UUVptbybRSQMdIoKHxBPBORg7C
# 732ITEFVaVthlHPao4gGMv+jMSG0IHRq4qF9Mst640YFRoHP6hln5f1QAQKgyGQR
# ONvph81ojVPu9UBqK6EGhX8kI5BP5FhmuDKTI+nOmbAw0UEPW91b/b2r2eRNagSF
# wQ47Qv03MIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG
# 9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEy
# MDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIw
# MTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
# AOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az
# /1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V2
# 9YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oa
# ezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkN
# yjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7K
# MtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRf
# NN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SU
# HDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoY
# WmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5
# C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8
# FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TAS
# BgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1
# Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUw
# UzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIB
# hjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fO
# mhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9w
# a2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggr
# BgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNv
# bS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3
# DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEz
# tTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJW
# AAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G
# 82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/Aye
# ixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI9
# 5ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1j
# dEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZ
# KCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xB
# Zj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuP
# Ntq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvp
# e784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCA1Aw
# ggI4AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMScw
# JQYDVQQLEx5uU2hpZWxkIFRTUyBFU046REMwMC0wNUUwLUQ5NDcxJTAjBgNVBAMT
# HE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMVAM2v
# FFf+LPqyzWUEJcbw/UsXEPR7oIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDsZS2TMCIYDzIwMjUwOTA1MDkzNjE5
# WhgPMjAyNTA5MDYwOTM2MTlaMHcwPQYKKwYBBAGEWQoEATEvMC0wCgIFAOxlLZMC
# AQAwCgIBAAICSjwCAf8wBwIBAAICEf8wCgIFAOxmfxMCAQAwNgYKKwYBBAGEWQoE
# AjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
# hkiG9w0BAQsFAAOCAQEAcobZHGEe8kLACC7mUcC9hZVc3F4oxaC/pEWEHiGXUZwn
# MjtIT49vQqCZ4A50CCPw4c9Ev3SKe7twWnZDyoi4y35t9BJ+Rx5ogA2JRUWtNnae
# Y6+ycnbAuZYo9xu4f2x1Ah8E+tkJsDYVqrH+pvvx+TIMJVw7JKQd+g2IOJbGh7TY
# xLozxG2Vpagfbuarq6pK1825ZUS0nLCMYbmq4QWlcaJ+kihCgcRpejQmtSvL0y5O
# b8C2q9O/xiUmKAe1NZ7d4UcG33Of6u670OV4PjQyjB6rnDTsTiV3oGrCNJUT+2FF
# BtNuXICqt84soS8DtJPiLH/LxupFt9UbExFASXSIlzGCBA0wggQJAgEBMIGTMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAACA7seXAA4bHTKAAEAAAID
# MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# LwYJKoZIhvcNAQkEMSIEIKED5HL9QAGS4EAMx+58mnQ3JJi+Bdpc7VlcnBGGWqTa
# MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgSwPdG3GW9pPEU5lmelDDQOSw
# +ZV26jlLIr2H3D76Ey0wgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMAITMwAAAgO7HlwAOGx0ygABAAACAzAiBCCBAeNLWXt7uB3RNk60Bv8moJiG
# +tDcoeOvDoohNnqgTzANBgkqhkiG9w0BAQsFAASCAgByozww3KbfPxiPZB7DnCMc
# rH0Z242lEpp4mtmJVlEqvXjPFJbNrD+unOfBragUNAEXy7F+kqN09SkgD/eErb6/
# bPjNwqm2BYRDFWcP9MK0mG4xcFIx1x1L0PfqPMEqxVyAWoO++41fnjHTVW6CzH1R
# SobirL0jxaL2xLmvRCHblf5kbY5YLYACfRXp1ZaUvDJMZiyiFs/LlD33qlSgKzKv
# 0s5ofohCXxemWuOUFR95vn0NfpCeT8aYYigemyQXZw/3+upLJip/kvQwmKjKSZmZ
# Du+TrFfMOoCVLjCyBu5xbr4nVzJ2iF229ObwBFGFkwULofW90QJbsQGcFXdTb+RX
# tUzpteFqqoUYdbv4nAROnnl/7G/6ijADu9q9H5DoyBGSCT2z4oBf0AOTPql4uhgR
# d1/7JB8TLMGEmH90/UTJ9oF/NPJdu6hREi+4x425MlayErseBesvhI5wRHq5YTx+
# NKbh+a2TIV5nlfLrXUtDHXaeTEJ6WICTrN1DTa3IKmmajWrleZxigudKSqpiwkWu
# dVZTNADvmJDD14iA3WWk47K6rMc2LxBI1w+6Cju+eflVhSYFTf+7BsB7vBhyNXTt
# uShTnhbZt65PaWUqmX0iHhLxErIQ87dphz+XzgGa004+Vu3B1em6tZKmrpCD7gKX
# 3iohpF7Xm4BPE6vh+RvGCQ==
# SIG # End signature block
