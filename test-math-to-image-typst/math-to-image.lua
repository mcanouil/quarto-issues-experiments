--[[
# MIT License
#
# Copyright (c) 2026 Mickaël Canouil
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
]]

--- Converts math equations to images using Typst rendering.
---
--- This filter processes Math elements in the Pandoc AST and converts them
--- to images using Typst backend. Supports PNG and SVG output formats.
--- Configuration is handled via document metadata options:
--- - math-format: 'png' or 'svg' (default: 'png')
--- - math-convert: 'display', 'inline', or 'full' (default: 'display')
--- - math-dpi: number for PNG resolution (default: 300)
--- - math-inline-dpi: number for inline PNG resolution (default: 150)
--- - math-inline-height: CSS height for inline maths (default: '0.15in')
--- - math-embed: boolean to embed in mediabag (default: true)
---
--- @module math_to_image
--- @author Mickaël Canouil
--- @license MIT
--- @copyright 2025 Mickaël Canouil

-- Constants
local EXTENSION_NAME = 'math-to-image'
local DEFAULT_FORMAT = 'png'
local DEFAULT_CONVERT = 'display'
local DEFAULT_DPI = 300
local DEFAULT_INLINE_DPI = 150
local DEFAULT_INLINE_HEIGHT = '0.15in'
local DEFAULT_EMBED = true
local IMAGE_DIR = '_math_images'

-- Module state
local options = {}

--- Reads filter options from document metadata.
---
--- Extracts configuration options from the document's metadata with sensible defaults.
--- Validates option values and logs warnings for invalid configurations.
---
--- @param meta table Pandoc document metadata
--- @return table Options table with keys: format, convert, dpi, inline_dpi, inline_height, embed
local function read_options(meta)
  local opts = {
    format = DEFAULT_FORMAT,
    convert = DEFAULT_CONVERT,
    dpi = DEFAULT_DPI,
    inline_dpi = DEFAULT_INLINE_DPI,
    inline_height = DEFAULT_INLINE_HEIGHT,
    embed = DEFAULT_EMBED
  }

  -- Read math-format option
  if meta['math-format'] then
    local format = pandoc.utils.stringify(meta['math-format']):lower()
    if format == 'png' or format == 'svg' then
      opts.format = format
    else
      io.stderr:write('[' .. EXTENSION_NAME .. '] Invalid math-format: ' .. format ..
        '\nExpected: png or svg\nUsing default: ' .. DEFAULT_FORMAT .. '\n')
    end
  end

  -- Read math-convert option
  if meta['math-convert'] then
    local convert = pandoc.utils.stringify(meta['math-convert']):lower()
    if convert == 'display' or convert == 'inline' or convert == 'full' then
      opts.convert = convert
    else
      io.stderr:write('[' .. EXTENSION_NAME .. '] Invalid math-convert: ' .. convert ..
        '\nExpected: display, inline, or full\nUsing default: ' .. DEFAULT_CONVERT .. '\n')
    end
  end

  -- Read math-dpi option
  if meta['math-dpi'] then
    local dpi = tonumber(pandoc.utils.stringify(meta['math-dpi']))
    if dpi and dpi > 0 then
      opts.dpi = dpi
    else
      io.stderr:write('[' .. EXTENSION_NAME .. '] Invalid math-dpi: ' .. tostring(dpi) ..
        '\nExpected: positive number\nUsing default: ' .. tostring(DEFAULT_DPI) .. '\n')
    end
  end

  -- Read math-inline-dpi option
  if meta['math-inline-dpi'] then
    local inline_dpi = tonumber(pandoc.utils.stringify(meta['math-inline-dpi']))
    if inline_dpi and inline_dpi > 0 then
      opts.inline_dpi = inline_dpi
    else
      io.stderr:write('[' .. EXTENSION_NAME .. '] Invalid math-inline-dpi: ' .. tostring(inline_dpi) ..
        '\nExpected: positive number\nUsing default: ' .. tostring(DEFAULT_INLINE_DPI) .. '\n')
    end
  end

  -- Read math-inline-height option
  if meta['math-inline-height'] then
    local height = pandoc.utils.stringify(meta['math-inline-height'])
    if height and height ~= '' then
      opts.inline_height = height
    else
      io.stderr:write('[' .. EXTENSION_NAME .. '] Invalid math-inline-height: ' .. tostring(height) ..
        '\nExpected: CSS height value (e.g., 0.15in, 1em)\nUsing default: ' .. DEFAULT_INLINE_HEIGHT .. '\n')
    end
  end

  -- Read math-embed option
  if meta['math-embed'] then
    local embed = meta['math-embed']
    if type(embed) == 'boolean' then
      opts.embed = embed
    else
      local embed_str = pandoc.utils.stringify(embed):lower()
      opts.embed = embed_str ~= 'false'
    end
  end

  return opts
end

--- Generates a hash of math content for caching.
---
--- Uses Pandoc's built-in SHA1 hashing to create a deterministic 8-character hash
--- of the math content for use in cache filenames.
---
--- @param content string The math LaTeX content
--- @return string Hash string (8 characters)
local function hash_content(content)
  local sha1 = pandoc.utils.sha1(content)
  return sha1:sub(1, 8)
end

--- Determines if a Math element should be converted.
---
--- Checks the MathType of the element against the configured conversion mode
--- to determine if it should be rendered as an image.
---
--- @param math pandoc.Math The math element to check
--- @param convert_mode string Mode: 'full', 'inline', or 'display'
--- @return boolean True if the element should be converted to an image
local function should_convert_math(math, convert_mode)
  if convert_mode == 'full' then
    return true
  elseif convert_mode == 'inline' then
    return math.mathtype == 'InlineMath'
  elseif convert_mode == 'display' then
    return math.mathtype == 'DisplayMath'
  end
  return false
end

--- Creates a Typst file with math content.
---
--- Generates a temporary Typst file with appropriate preamble and math content.
--- The page is set to auto-size to fit the rendered math naturally.
--- For inline math, uses a smaller font size and reduced margins to keep
--- images within text line height.
---
--- @param math_content string LaTeX math content
--- @param is_display boolean True for display math, false for inline
--- @return string Path to created Typst file
local function create_typst_file(math_content, is_display)
  -- Create temporary file name
  local temp_file = os.tmpname() .. '.typ'

  -- Set appropriate font size for display vs inline
  -- Inline math uses much smaller font to fit within line height
  local font_size = is_display and '12pt' or '8pt'

  -- Use math mode syntax that Typst recognises
  -- Typst's math mode accepts LaTeX syntax
  local margin = is_display and '10pt' or '2pt'
  local typst_content = '#set page(width: auto, height: auto, margin: ' .. margin .. ')\n' ..
      '#set text(size: ' .. font_size .. ')\n' ..
      '$ ' .. math_content .. ' $'

  -- Write to temporary file
  local file = io.open(temp_file, 'w')
  if not file then
    error('Failed to create temporary Typst file: ' .. temp_file)
  end
  file:write(typst_content)
  file:close()

  return temp_file
end

--- Renders math to image using Typst.
---
--- Executes the `quarto typst compile` command to render a Typst file
--- to the specified image format. Handles error conditions gracefully.
---
--- @param typst_path string Path to Typst source file
--- @param output_path string Path for output image
--- @param format string Image format: 'png' or 'svg'
--- @param dpi number DPI for PNG output (ignored for SVG)
--- @param is_display boolean True for display math, false for inline
--- @return boolean, string|nil Success status and error message if failed
local function render_math_image(typst_path, output_path, format, dpi, is_display)
  local success, result

  if format == 'png' then
    -- For PNG, include DPI setting
    success, result = pcall(function()
      return pandoc.pipe(
        'quarto',
        { 'typst', 'compile', typst_path, output_path, '--format', 'png', '--ppi', tostring(dpi) },
        ''
      )
    end)
  else
    -- For SVG, no DPI setting needed
    success, result = pcall(function()
      return pandoc.pipe(
        'quarto',
        { 'typst', 'compile', typst_path, output_path, '--format', 'svg' },
        ''
      )
    end)
  end

  if not success then
    return false, 'Command execution failed: ' .. tostring(result)
  end

  -- Check if output file was created
  local file = io.open(output_path, 'r')
  if not file then
    return false, 'Output file was not created: ' .. output_path
  end
  file:close()

  return true, nil
end

--- Ensures the image directory exists.
---
--- Creates the IMAGE_DIR directory if it does not already exist.
---
--- @return boolean True if directory exists or was created, false otherwise
local function ensure_image_dir()
  local success, _result = pcall(function()
    os.execute('mkdir -p ' .. IMAGE_DIR)
  end)

  if not success then
    io.stderr:write(
      '[' .. EXTENSION_NAME .. '] Failed to create image directory: ' .. IMAGE_DIR .. '\n'
    )
    return false
  end

  return true
end

--- Converts a Math element to an Image element.
---
--- Orchestrates the full conversion process: creates a Typst file, renders it
--- to an image, and returns a corresponding Image element. If conversion fails,
--- returns nil and the original Math element should be preserved.
---
--- @param math pandoc.Math The math element to convert
--- @param opts table Filter options
--- @return pandoc.Image|nil The image element or nil if conversion failed
local function convert_math_to_image(math, opts)
  -- Trim and normalize math content
  local math_text = math.text:gsub('^%s+', ''):gsub('%s+$', '')

  -- Skip empty math content
  if not math_text or math_text == '' then
    return nil
  end

  -- Skip math with labels (to preserve cross-references)
  if math_text:find('\\label') then
    return nil
  end

  -- Wrap consecutive letters in parentheses to prevent Typst from treating
  -- them as multi-character variable names. This fixes the incompatibility
  -- between LaTeX and Typst math syntax by ensuring each letter is isolated.
  -- Process multiple times to handle all adjacent letter sequences
  local prev_text = ''
  while prev_text ~= math_text do
    prev_text = math_text
    -- Replace pairs of adjacent letters with parenthesized versions
    math_text = math_text:gsub('([a-zA-Z])([a-zA-Z])', '(%1)%2')
  end

  -- Ensure image directory exists
  if not ensure_image_dir() then
    return nil
  end

  -- Generate cache key
  local content_hash = hash_content(math_text)
  local is_display = math.mathtype == 'DisplayMath'
  local math_type_str = is_display and 'display' or 'inline'
  local image_filename = 'math-' .. content_hash .. '-' .. math_type_str .. '.' .. opts.format
  local image_path = IMAGE_DIR .. '/' .. image_filename

  -- Try to render if image doesn't exist
  local file_exists = io.open(image_path, 'r')
  if file_exists then
    file_exists:close()
  end

  if not file_exists then
    -- Create temporary Typst file
    local typst_file
    local success, typst_err = pcall(function()
      typst_file = create_typst_file(math_text, is_display)
    end)

    if not success then
      io.stderr:write(
        '[' .. EXTENSION_NAME .. '] Failed to create Typst file: ' .. tostring(typst_err) ..
        '\nMath content: ' .. math_text .. '\n'
      )
      return nil
    end

    -- Render to image
    -- Use inline_dpi for inline math, regular dpi for display math
    local dpi = is_display and opts.dpi or opts.inline_dpi
    local render_success, render_err = render_math_image(typst_file, image_path, opts.format, dpi, is_display)

    -- Clean up temporary Typst file
    if typst_file then
      local temp_file = io.open(typst_file, 'r')
      if temp_file then
        temp_file:close()
        os.remove(typst_file)
      end
    end

    if not render_success then
      io.stderr:write(
        '[' .. EXTENSION_NAME .. '] Failed to render math: ' .. render_err ..
        '\nMath content: ' .. math_text .. '\n'
      )
      return nil
    end
  end

  -- Create Image element with sizing attributes for inline maths
  local image_alt = '' -- Could optionally use math.text as alt text
  local image = pandoc.Image({ pandoc.Str(image_alt) }, image_path)

  -- For inline math, set height only to scale proportionally
  if not is_display then
    image.attr = pandoc.Attr('', {}, { { 'height', opts.inline_height } })
  end

  -- Optionally embed in mediabag for portability
  if opts.embed then
    local success, embed_err = pcall(function()
      local file_content = io.open(image_path, 'rb'):read('*a')
      pandoc.mediabag.insert(image_path, 'image/' .. opts.format, file_content)
    end)

    if not success then
      io.stderr:write(
        '[' .. EXTENSION_NAME .. '] Failed to embed image in mediabag: ' .. tostring(embed_err) .. '\n'
      )
      -- Continue anyway, image is still usable from disk
    end
  end

  return image
end

--- Processes Math elements and converts them to images.
---
--- This is the main filter function that gets applied to each Math element
--- in the document. It checks configuration and converts if appropriate.
---
--- @param math pandoc.Math The math element to process
--- @return pandoc.Image|pandoc.Math Converted image or original math element
local function math_filter(math)
  -- Skip if conversion mode doesn't match this element
  if not should_convert_math(math, options.convert) then
    return math
  end

  -- Attempt conversion
  local image = convert_math_to_image(math, options)
  if image then
    return image
  end

  -- Return original if conversion failed
  return math
end

-- Return filter table with initialization
return {
  {
    Meta = function(meta)
      -- Read options from metadata on first pass
      if not options.format then
        options = read_options(meta)
      end
      return meta
    end
  },
  {
    Math = math_filter
  }
}
