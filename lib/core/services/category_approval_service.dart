import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/models/category_requirement.dart';
import 'package:chegaja_v2/core/models/provider_category_approval.dart';
import 'package:chegaja_v2/core/models/sensitive_category_request.dart';

class CategoryApprovalService {
  CategoryApprovalService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            (firestore == null
                ? FirebaseFunctions.instanceFor(
                    region: AppConfig.functionsRegion,
                  )
                : null),
        _useAuthoritativeFunctions = firestore == null;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;
  final bool _useAuthoritativeFunctions;

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
    if (_useAuthoritativeFunctions) {
      final response = await _functions!
          .httpsCallable('categories_submitSensitiveRequest')
          .call(<String, dynamic>{
        'categoryId': categoryId,
        'evidenceTypes': evidenceTypesToFirestore(evidenceTypes),
        'evidenceText': evidenceText,
        'portfolioUrls': portfolioUrls,
        'documentRefs': documentRefs,
      });
      final responseData = Map<String, dynamic>.from(response.data as Map);
      final requestId = responseData['requestId']?.toString() ?? '';
      final now = DateTime.now();
      return SensitiveCategoryRequest(
        id: requestId,
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
    }
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

  Future<List<CategoryRequirement>> getActiveCategoryRequirements() async {
    final snap = await _firestore.collection('categoryRequirements').get();
    final requirements = snap.docs
        .map(CategoryRequirement.fromDoc)
        .where((requirement) => requirement.isActive)
        .toList(growable: false);
    requirements.sort((a, b) => a.categoryName.compareTo(b.categoryName));
    return requirements;
  }

  Future<List<ProviderCategoryApproval>> getProviderCategoryApprovals(
    String providerId,
  ) async {
    final snap = await _firestore
        .collection('provider_private')
        .doc(providerId)
        .collection('categoryApprovals')
        .get();
    return snap.docs
        .map(ProviderCategoryApproval.fromDoc)
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

  Future<void> resubmitSensitiveCategoryRequest({
    required String requestId,
    required List<EvidenceType> evidenceTypes,
    String? evidenceText,
    List<String> portfolioUrls = const [],
    List<String> documentRefs = const [],
  }) async {
    if (_useAuthoritativeFunctions) {
      final existing = await _firestore
          .collection('sensitiveCategoryRequests')
          .doc(requestId)
          .get();
      final categoryId = existing.data()?['categoryId']?.toString() ?? '';
      await _functions!
          .httpsCallable('categories_submitSensitiveRequest')
          .call(<String, dynamic>{
        'categoryId': categoryId,
        'evidenceTypes': evidenceTypesToFirestore(evidenceTypes),
        'evidenceText': evidenceText,
        'portfolioUrls': portfolioUrls,
        'documentRefs': documentRefs,
      });
      return;
    }
    await _firestore
        .collection('sensitiveCategoryRequests')
        .doc(requestId)
        .update(<String, dynamic>{
      'status': sensitiveCategoryRequestStatusToFirestore(
        SensitiveCategoryRequestStatus.pendingReview,
      ),
      'evidenceTypes': evidenceTypesToFirestore(evidenceTypes),
      if (evidenceText != null) 'evidenceText': evidenceText,
      'portfolioUrls': portfolioUrls,
      'documentRefs': documentRefs,
      'submittedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isCategoryApprovedForProvider(
    String providerId,
    String categoryId,
  ) async {
    final snap = await _firestore
        .collection('provider_private')
        .doc(providerId)
        .collection('categoryApprovals')
        .doc(categoryId)
        .get();
    if (!snap.exists) return false;
    return ProviderCategoryApproval.fromDoc(snap).isCurrentlyApproved;
  }
}
