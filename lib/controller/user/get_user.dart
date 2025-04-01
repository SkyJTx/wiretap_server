import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:wiretap_server/constant/constant.dart';
import 'package:wiretap_server/data_model/data.dart';
import 'package:wiretap_server/data_model/paginable_data.dart';
import 'package:wiretap_server/data_model/user.dart';
import 'package:wiretap_server/repo/database/entity/user_entity.dart';
import 'package:wiretap_server/data_model/error_base.dart';
import 'package:wiretap_server/repo/user/user_repo.dart';

Future<Response> getSelf(Request req) async {
  late final UserEntity user;
  try {
    user = req.context['user'] as UserEntity;
  } catch (e) {
    return failedToGetUserFromRequest;
  }

  return Response.ok(
    Data(message: 'User found', data: UserSafe.fromEntity(user).toMap()).toJson(),
    headers: jsonHeader,
  );
}

Future<Response> getUserById(Request req) async {
  late final int id;
  try {
    id = int.parse(req.params['id']!);
  } catch (e) {
    return badRequest;
  }

  late final UserEntity targetUser;
  try {
    targetUser = await UserRepo().getUserById(id);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get user');
  }

  return Response.ok(
    Data(message: 'User found', data: UserSafe.fromEntity(targetUser).toMap()).toJson(),
    headers: jsonHeader,
  );
}

Future<Response> getUsers(Request req) async {
  late final int userPerPage;
  late final int page;
  String? searchParam;
  try {
    userPerPage = int.parse(req.url.queryParameters['userPerPage']!);
    page = int.parse(req.url.queryParameters['page']!);
    searchParam = req.url.queryParameters['searchParam'];
  } catch (e) {
    return badRequest;
  }

  late final List<UserEntity> users;
  late final int totalUsers;
  late final int totalPages;
  try {
    users = await UserRepo().getUsers(userPerPage, page, searchParam: searchParam);
    totalUsers = await UserRepo().getUserCount();
    totalPages = await UserRepo().getPageCount(userPerPage);
  } on ErrorBase catch (e) {
    return e.toResponse();
  } catch (e) {
    return ErrorType.internalServerError.toResponse('Failed to get users');
  }

  return Response.ok(
    PaginableData(
      message: 'Users found',
      totalPage: totalPages,
      totalSize: totalUsers,
      size: userPerPage,
      page: page,
      data: users.map((e) => UserSafe.fromEntity(e).toMap()).toList(),
    ).toJson(),
    headers: jsonHeader,
  );
}
