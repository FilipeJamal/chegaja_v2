import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PedidoAnexosWidget extends StatefulWidget {
  final List<String> initialUrls;
  final ValueChanged<List<String>> onChanged;
  final bool readOnly;
  final String? pedidoId; // Se nulo, estamos a criar pedido (upload para temp)

  const PedidoAnexosWidget({
    super.key,
    required this.initialUrls,
    required this.onChanged,
    this.readOnly = false,
    this.pedidoId,
  });

  @override
  State<PedidoAnexosWidget> createState() => _PedidoAnexosWidgetState();
}

class _PedidoAnexosWidgetState extends State<PedidoAnexosWidget> {
  late List<String> _urls;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _urls = List.from(widget.initialUrls);
  }

  @override
  void didUpdateWidget(covariant PedidoAnexosWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUrls != oldWidget.initialUrls) {
      _urls = List.from(widget.initialUrls);
    }
  }

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final folder = widget.pedidoId != null
        ? 'pedidos/${widget.pedidoId}/anexos'
        : 'temp/anexos_$ts'; 
    
    // NOTA: Se for temp, depois deveria haver lógica de limpeza, mas para MVP ok.
    // Melhor: se tivermos user ID, 'temp/{uid}/...'. 
    // Como não temos acesso fácil ao uid aqui sem AuthService, vamos simplificar.
    
    final path = '$folder/${ts}_$fileName';
    final ref = FirebaseStorage.instance.ref().child(path);
    final meta = contentType != null ? SettableMetadata(contentType: contentType) : null;
    
    final task = await ref.putData(bytes, meta);
    return await task.ref.getDownloadURL();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_uploading) return;
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      
      setState(() => _uploading = true);
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last;
      
      // Upload
      final url = await _uploadBytes(
        bytes: bytes,
        fileName: picked.name,
        contentType: 'image/$ext',
      );
      
      setState(() {
        _urls.add(url);
        _uploading = false;
      });
      widget.onChanged(_urls);
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar imagem: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    if (_uploading) return;
    try {
      final res = await FilePicker.platform.pickFiles(withData: true);
      if (res == null || res.files.isEmpty) return;

      final f = res.files.first;
      final bytes = f.bytes;
      if (bytes == null) return;

      setState(() => _uploading = true);
      
      final url = await _uploadBytes(
        bytes: bytes,
        fileName: f.name,
      );

      setState(() {
        _urls.add(url);
        _uploading = false;
      });
      widget.onChanged(_urls);
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar ficheiro: $e')),
        );
      }
    }
  }

  void _removeUrl(String url) {
    setState(() {
      _urls.remove(url);
    });
    widget.onChanged(_urls);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_urls.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _urls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final url = _urls[index];
                final isImage = url.contains('.jpg') || url.contains('.jpeg') || url.contains('.png') || url.contains('image');
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: isImage
                            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                            : null,
                      ),
                      child: !isImage
                          ? const Center(child: Icon(Icons.insert_drive_file, size: 40, color: Colors.grey))
                          : null,
                    ),
                    if (!widget.readOnly)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeUrl(url),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        
        if (_urls.isNotEmpty) const SizedBox(height: 12),

        if (!widget.readOnly)
          Row(
            children: [
              if (_uploading)
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ElevatedButton.icon(
                onPressed: _uploading ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo),
                label: const Text('Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _uploading ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Câmera'),
                                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 8),
              // File picker for completeness
              IconButton(
                onPressed: _uploading ? null : _pickFile,
                icon: const Icon(Icons.attach_file),
                tooltip: 'Anexar Ficheiro',
              ),
            ],
          ),
      ],
    );
  }
}
