app.controller("ViewFriendsController", function($scope, $http){

	$scope.friends = [];

	$http.get('/api/friends').success(function(data, status, headers, config) {
		$scope.friends = data.friends;
		console.log(data);
	}).

	error(function(data, status, headers, config) {
		console.log('there was an error');
	});
});
