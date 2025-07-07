#!/usr/bin/env python3
"""
Generates basic seed files for fuzzing.
Creates proper file formats that can be used with any fuzzing target.
"""
import os
import argparse
from pathlib import Path

def generate_txt(path: Path):
    """Generate a simple text file"""
    path.write_text("hello world\nthis is a test file\nline 3\nline 4")

def generate_simple_txt(path: Path):
    """Generate very simple text file"""
    path.write_text("A")

def generate_png(path: Path):
    """Generate minimal valid PNG (1x1 transparent pixel)"""
    path.write_bytes(bytes.fromhex(
        '89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c489'
        '0000000a49444154789c63000100000500010d0a2db40000000049454e44ae426082'
    ))

def generate_simple_png(path: Path):
    """Generate PNG header only (malformed)"""
    path.write_bytes(bytes.fromhex('89504e470d0a1a0a'))

def generate_jpg(path: Path):
    """Generate minimal valid JPEG (1x1 black pixel)"""
    path.write_bytes(bytes.fromhex(
        'ffd8ffe000104a46494600010100000100010000ffdb0043000101010101010101'
        '010101010101010101010101010101010101010101010101010101010101010101'
        '01010101010101010101010101010101010101ffc00011080001000101011100ff'
        'c4001f0000010501010101010100000000000000000102030405060708090a0bff'
        'da000c03010002110311003f00f6bfd9'
    ))

def generate_simple_jpg(path: Path):
    """Generate JPEG header only (malformed)"""
    path.write_bytes(bytes.fromhex('ffd8ffe0'))

def generate_pdf(path: Path):
    """Generate minimal valid PDF"""
    pdf_content = (
        b'%PDF-1.1\n'
        b'1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n'
        b'2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n'
        b'3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 10 10] >>\nendobj\n'
        b'xref\n0 4\n0000000000 65535 f \n0000000009 00000 n \n'
        b'0000000058 00000 n \n0000000112 00000 n \n'
        b'trailer\n<< /Size 4 /Root 1 0 R >>\n'
        b'startxref\n170\n%%EOF'
    )
    path.write_bytes(pdf_content)

def generate_simple_pdf(path: Path):
    """Generate PDF header only (malformed)"""
    path.write_bytes(b'%PDF-1.1\n')

def generate_bmp(path: Path):
    """Generate minimal valid BMP (1x1 pixel)"""
    # BMP header for 1x1 24-bit image
    bmp_data = bytes([
        0x42, 0x4D,  # "BM" signature
        0x36, 0x00, 0x00, 0x00,  # File size (54 bytes)
        0x00, 0x00, 0x00, 0x00,  # Reserved
        0x36, 0x00, 0x00, 0x00,  # Offset to pixel data
        0x28, 0x00, 0x00, 0x00,  # Header size
        0x01, 0x00, 0x00, 0x00,  # Width (1)
        0x01, 0x00, 0x00, 0x00,  # Height (1)
        0x01, 0x00,              # Planes
        0x18, 0x00,              # Bits per pixel (24)
        0x00, 0x00, 0x00, 0x00,  # Compression
        0x00, 0x00, 0x00, 0x00,  # Image size
        0x00, 0x00, 0x00, 0x00,  # X pixels per meter
        0x00, 0x00, 0x00, 0x00,  # Y pixels per meter
        0x00, 0x00, 0x00, 0x00,  # Colors used
        0x00, 0x00, 0x00, 0x00,  # Important colors
        0x00, 0x00, 0x00         # Pixel data (1 black pixel)
    ])
    path.write_bytes(bmp_data)

def generate_simple_bmp(path: Path):
    """Generate BMP header only (malformed)"""
    path.write_bytes(b'BM')

def generate_gif(path: Path):
    """Generate minimal valid GIF (1x1 pixel)"""
    gif_data = bytes([
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61,  # "GIF89a"
        0x01, 0x00,  # Width (1)
        0x01, 0x00,  # Height (1) 
        0x00,        # Global color table flag
        0x00,        # Background color
        0x00,        # Pixel aspect ratio
        0x2C,        # Image separator
        0x00, 0x00, 0x00, 0x00,  # Left, top
        0x01, 0x00, 0x01, 0x00,  # Width, height
        0x00,        # Local color table flag
        0x02,        # LZW minimum code size
        0x02,        # Data sub-block size
        0x04, 0x01,  # LZW data
        0x00,        # Data sub-block terminator
        0x3B         # GIF trailer
    ])
    path.write_bytes(gif_data)

def generate_simple_gif(path: Path):
    """Generate GIF header only (malformed)"""
    path.write_bytes(b'GIF89a')

def generate_xml(path: Path):
    """Generate simple XML file"""
    xml_content = '''<?xml version="1.0" encoding="UTF-8"?>
<root>
    <item id="1">
        <name>Test Item</name>
        <value>123</value>
    </item>
</root>'''
    path.write_text(xml_content)

def generate_simple_xml(path: Path):
    """Generate minimal XML"""
    path.write_text('<?xml version="1.0"?><root></root>')

def generate_json(path: Path):
    """Generate simple JSON file"""
    json_content = '''{
    "name": "test",
    "value": 123,
    "items": ["a", "b", "c"],
    "nested": {
        "key": "value"
    }
}'''
    path.write_text(json_content)

def generate_simple_json(path: Path):
    """Generate minimal JSON"""
    path.write_text('{}')

def generate_html(path: Path):
    """Generate simple HTML file"""
    html_content = '''<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
</head>
<body>
    <h1>Hello World</h1>
    <p>This is a test page.</p>
</body>
</html>'''
    path.write_text(html_content)

def generate_simple_html(path: Path):
    """Generate minimal HTML"""
    path.write_text('<html><body>test</body></html>')

def generate_csv(path: Path):
    """Generate simple CSV file"""
    csv_content = '''name,age,city
John,25,New York
Jane,30,Los Angeles
Bob,35,Chicago'''
    path.write_text(csv_content)

def generate_simple_csv(path: Path):
    """Generate minimal CSV"""
    path.write_text('a,b,c\n1,2,3')

def generate_binary(path: Path):
    """Generate random binary data"""
    import struct
    data = struct.pack('<IIHH10s', 0x12345678, 100, 200, 16, 24, b'testdata12')
    path.write_bytes(data)

def generate_simple_binary(path: Path):
    """Generate simple binary data"""
    path.write_bytes(b'\x00\x01\x02\x03\x04\x05')

def generate_empty_file(path: Path):
    """Generate empty file"""
    path.write_bytes(b'')

def generate_large_file(path: Path):
    """Generate larger file for testing"""
    path.write_text("A" * 1000 + "\n" + "B" * 1000)

# Special generators for boundary conditions
def generate_null_bytes(path: Path):
    """Generate file with null bytes"""
    path.write_bytes(b'\x00' * 100)

def generate_high_ascii(path: Path):
    """Generate file with high ASCII values"""
    path.write_bytes(bytes(range(128, 256)))

def generate_mixed_content(path: Path):
    """Generate file with mixed binary and text content"""
    content = b'TEXT_START\x00\x01\x02\x03TEXT_MIDDLE\xff\xfe\xfdTEXT_END'
    path.write_bytes(content)

def main():
    parser = argparse.ArgumentParser(description="Generate seed files for fuzzing.")
    parser.add_argument('output_dir', help="Directory to save the seed files.")
    parser.add_argument('file_types', nargs='+', help="File types to generate (txt, png, jpg, pdf, bmp, gif, xml, json, html, csv, binary)")
    parser.add_argument('--simple', action='store_true', help="Generate simpler/malformed seed files")
    parser.add_argument('--boundary', action='store_true', help="Generate boundary condition test files")
    args = parser.parse_args()

    output_path = Path(args.output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Define generators
    if args.simple:
        generators = {
            'txt': generate_simple_txt,
            'png': generate_simple_png,
            'jpg': generate_simple_jpg,
            'pdf': generate_simple_pdf,
            'bmp': generate_simple_bmp,
            'gif': generate_simple_gif,
            'xml': generate_simple_xml,
            'json': generate_simple_json,
            'html': generate_simple_html,
            'csv': generate_simple_csv,
            'binary': generate_simple_binary,
            'bin': generate_simple_binary,
            'empty': generate_empty_file,
        }
    else:
        generators = {
            'txt': generate_txt,
            'png': generate_png,
            'jpg': generate_jpg,
            'pdf': generate_pdf,
            'bmp': generate_bmp,
            'gif': generate_gif,
            'xml': generate_xml,
            'json': generate_json,
            'html': generate_html,
            'csv': generate_csv,
            'binary': generate_binary,
            'bin': generate_binary,
        }

    print(f"Generating {'simple ' if args.simple else ''}seeds in: {output_path}")
    
    # Generate requested file types
    for file_type in args.file_types:
        if file_type in generators:
            seed_path = output_path / f"seed.{file_type}"
            generators[file_type](seed_path)
            print(f"  ✓ Created {seed_path.name}")
        else:
            print(f"  ✗ Unknown file type: {file_type}")
    
    # Generate boundary condition files if requested
    if args.boundary:
        print("  Generating boundary condition files...")
        boundary_generators = [
            ('empty', generate_empty_file),
            ('large', generate_large_file),
            ('nulls', generate_null_bytes),
            ('high_ascii', generate_high_ascii),
            ('mixed', generate_mixed_content),
        ]
        
        for name, generator in boundary_generators:
            seed_path = output_path / f"seed_{name}.dat"
            generator(seed_path)
            print(f"  ✓ Created {seed_path.name}")

if __name__ == '__main__':
    main()