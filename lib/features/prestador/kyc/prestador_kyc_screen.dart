
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chegaja_v2/core/services/kyc_service.dart';

class PrestadorKycScreen extends StatefulWidget {
  const PrestadorKycScreen({super.key});

  @override
  State<PrestadorKycScreen> createState() => _PrestadorKycScreenState();
}

class _PrestadorKycScreenState extends State<PrestadorKycScreen> {
  final _picker = ImagePicker();
  
  File? _frontImage;
  File? _backImage;
  
  bool _loading = true;
  bool _submitting = false;
  String _status = 'none'; // none, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _loading = true);
    // Aqui podiamos ler do repo ou do service. 
    // Como o service tem getKycStatus, usamos. Mas idealmente leriamos o doc todo se quisessmos mostrar as fotos antigas.
    // Para MVP, assumimos fluxo novo se for none/rejected.
    try {
      final s = await KycService.instance.getKycStatus();
      if (mounted) {
        setState(() {
          _status = s;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(bool isFront) async {
    if (_status == 'pending' || _status == 'approved') return;

    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(picked.path);
        } else {
          _backImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_frontImage == null || _backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, carrega ambas as fotos do documento.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // 1. Upload images
      final frontUrl = await KycService.instance.uploadDocument(_frontImage!, 'front');
      final backUrl = await KycService.instance.uploadDocument(_backImage!, 'back');

      // 2. Submit data
      await KycService.instance.submitKyc(frontUrl, backUrl);

      if (mounted) {
        setState(() {
          _status = 'pending';
          _submitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documentos enviados com sucesso! Aguarda aprovação.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')),
        );
      }
    }
  }

  Widget _buildImageCard(String label, File? image, bool isFront) {
    final canEdit = _status == 'none' || _status == 'rejected';
    
    return InkWell(
      onTap: () => _pickImage(isFront),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          image: image != null
              ? DecorationImage(
                  image: FileImage(image),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 14,
                    child: Icon(canEdit ? Icons.edit : Icons.check, size: 16, color: Colors.black),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Se aprovado
    if (_status == 'approved') {
      return Scaffold(
        appBar: AppBar(title: const Text('Verificação de Identidade')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, size: 80, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Conta Verificada!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Já podes aceitar pedidos sem restrições.'),
            ],
          ),
        ),
      );
    }

    // Se pendente
    if (_status == 'pending') {
      return Scaffold(
        appBar: AppBar(title: const Text('Verificação de Identidade')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Verificação em Análise',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Os teus documentos foram enviados e estão a ser analisados pela nossa equipa. Serás notificado em breve.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Se none ou rejected
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação de Identidade'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_status == 'rejected')
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(child: Text('A tua submissão anterior foi rejeitada. Por favor envia fotos mais nítidas.')),
                  ],
                ),
              ),
            
            const Text(
              'Para garantir a segurança da plataforma, precisamos de verificar a sua identidade.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            
            const Text('Frente do Bilhete de Identidade', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildImageCard('Toque para adicionar foto da Frente', _frontImage, true),
            
            const SizedBox(height: 24),
            
            const Text('Verso do Bilhete de Identidade', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildImageCard('Toque para adicionar foto do Verso', _backImage, false),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submeter para Revisão'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
