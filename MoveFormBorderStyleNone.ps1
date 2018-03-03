#Requires -PSEdition Desktop

using assembly System.Windows.Forms
using namespace System.Windows.Forms

$form = [Form]@{
	FormBorderStyle = "None"
}

$form.Add_MouseDown({
	$form.Capture = $false
	$m = [Message]::Create($form.Handle, 0xa1, (New-Object IntPtr(2)), [IntPtr]::Zero)
	$form.WindowTarget.DefWndProc([ref]$m)
})

$form.ShowDialog()