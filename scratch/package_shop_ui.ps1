Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'
$root = 'Z:/process/godot-remake/assets/ui/shop'
$out = 'Z:/process/godot-remake/output/shop_ui_kit'
New-Item -ItemType Directory -Force -Path $root, "$out/sources" | Out-Null
$gen = 'C:/Users/Usuario/.codex/generated_images/01a15ce7-22f4-7aa3-b4bf-433f8a552678'
$atlasPath = "$gen/exec-fd7e4718-da05-40d4-b51d-14e8bfb75b16.png"
$chromePath = "$gen/exec-b5285893-837f-4b7a-a53b-1c389f7200c4.png"
Copy-Item -LiteralPath $atlasPath -Destination "$out/sources/controls_atlas.png"
Copy-Item -LiteralPath $chromePath -Destination "$out/sources/chrome_atlas.png"
Copy-Item -LiteralPath "$gen/exec-f6c93929-da1d-41bb-926c-a71d331f9203.png" -Destination "$root/background.png"
Copy-Item -LiteralPath 'C:/Users/Usuario/AppData/Local/Temp/codex-clipboard-63e06ad7-3e89-44cb-87b7-dd4e271347ea.png' -Destination "$out/approved_concept.png"
$manifest = [System.Collections.Generic.List[object]]::new()
function Export-Sprite($source, $name, $x, $y, $w, $h) {
    $left=$x+$w; $top=$y+$h; $right=-1; $bottom=-1
    for($py=$y; $py -lt $y+$h; $py++) {
        for($px=$x; $px -lt $x+$w; $px++) {
            if($source.GetPixel($px,$py).A -gt 8) {
                $left=[Math]::Min($left,$px); $top=[Math]::Min($top,$py)
                $right=[Math]::Max($right,$px); $bottom=[Math]::Max($bottom,$py)
            }
        }
    }
    if($right -lt 0) { throw "Empty sprite: $name" }
    $left=[Math]::Max($x,$left-2); $top=[Math]::Max($y,$top-2)
    $right=[Math]::Min($x+$w-1,$right+2); $bottom=[Math]::Min($y+$h-1,$bottom+2)
    $rect=[System.Drawing.Rectangle]::new($left,$top,$right-$left+1,$bottom-$top+1)
    $sprite=$source.Clone($rect,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $sprite.Save("$root/$name.png",[System.Drawing.Imaging.ImageFormat]::Png)
    $manifest.Add([ordered]@{file="$name.png";width=$sprite.Width;height=$sprite.Height;source_region=@($left,$top,$rect.Width,$rect.Height);transparent=$true})
    $sprite.Dispose()
}
$atlas=[System.Drawing.Bitmap]::new($atlasPath)
$names=@('tab_normal','tab_hover','tab_pressed','tab_selected','price_normal','price_hover','price_disabled','balance_panel','back_normal','back_hover','back_pressed','back_disabled','selection_corner','scroll_track','scroll_thumb','scroll_arrow_down')
$ys=@(0,250,470,700); $hs=@(250,220,230,324)
for($i=0;$i -lt 16;$i++) { $row=[int][Math]::Floor($i/4); Export-Sprite $atlas $names[$i] (($i%4)*384) $ys[$row] 384 $hs[$row] }
$atlas.Dispose()
$chrome=[System.Drawing.Bitmap]::new($chromePath)
Export-Sprite $chrome 'title_card_shop' 0 0 1536 360
Export-Sprite $chrome 'header_strip' 0 360 1536 320
Export-Sprite $chrome 'footer_strip' 0 680 1536 344
$chrome.Dispose()
$manifest | ConvertTo-Json -Depth 5 | Set-Content "$out/sprite_manifest.json" -Encoding utf8
$manifest | Format-Table file,width,height
