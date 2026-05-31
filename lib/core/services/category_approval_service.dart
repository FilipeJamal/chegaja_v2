import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/models/category_requirement.dart';
import 'package:chegaja_v2/core/models/provider_category_approval.dart';
import 'package:chegaja_v2/core/models/sensitive_category_request.dart';

class CategoryApprovalService {
  CategoryApprovalService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  SensitiveCategoryRequest buildRequestDraft({
    required String providerId,
    required String categoryId,
    required String categoryName,
    List<EvidenceType> evidenceTypes = const [],
    String? evidenceText,
    List<String> portfolioUrls = const [],
    List<String> documentRefs = const [],
  }) {
    return SensitiveCategoryRequest.draft(
      providerId: providerId,
      categoryId: categoryId,
      categoryName: categoryName,
      evidenceTypes: evidenceTypes,
      evidenceText: evidenceText,
      portfolioUrls: portfolioUrls,
      documentRefs: documentRefs,
    );
  }

  Future<SensitiveCategoryRequest> createSensitiveCategoryRequest({
    required String providerId,
    required String categoryId,
    required String categoryName,
    List<EvidenceType> evidenceTypes = const [],
    String? evidenceText,
    List<String> portfolioUrls = const [],
    List<String> documentRefs = const [],
  }) async {
    final ref = _firestore.collection('sensitiveCategoryRequests').doc();
    final now = DateTime.now();
    final request = SensitiveCategoryRequest(
      id: ref.id,
      providerId: providerId,
      categoryId: categoryId,
      categoryName: categoryName,
      status: SensitiveCategoryRequestStatus.pendingReview,
      evidenceTypes: evidenceTypes,
      evidenceText: evidenceText,
      portfolioUrls: portfolioUrls,
      documentRefs: documentRefs,
      createdAt: now,
      updatedAt: now,
      submittedAt: now,
    );

    await ref.set(<String, dynamic>{
      ...request.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'submittedAt': FieldValue.serverTimestamp(),
    });

    return request;
  }

  Future<List<SensitiveCategoryRequest>> getProviderCategoryRequests(
    String providerId,
  ) async {
    final snap = await _firestore
        .collection('sensitiveCategoryRequests')
        .where('providerId', isEqualTo: providerId)
        .get();
    return snap.docs
        .map(SensitiveCategoryRequest.fromDoc)
        .toList(growable: false);
  }

  Stream<List<SensitiveCategoryRequest>> streamProviderCategoryRequests(
    String providerId,
  ) {
    return _firestore
        .collection('sensitiveCategoryRequests')
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(SensitiveCategoryRequest.fromDoc)
              .toList(growable: false),
        );
  }

  Future<CategoryRequirement?> getCategoryRequirement(String categoryId) async {
    final snap = await _firestore
        .collection('categoryRequirements')
        .doc(categoryId)
        .get();
    if (!snap.exists) return null;
    return CategoryRequirement.fromDoc(snap);
  }

  Future<bool> isCategoryApprovedForProvider(
    String providerId,
    String categoryId,
  ) async {
    final snap = await _firestore
        .collection('prestadores')
        .doc(providerId)
        .collection('categoryApprovals')
        .doc(categoryId)
        .get();
    if (!snap.exists) return false;
    return ProviderCategoryApproval.fromDoc(snap).isCurrentlyApproved;
  }
}
