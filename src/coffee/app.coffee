
angular
  .module('liveController', [])
  .controller('MainCtrl', ['$scope', '$http', '$interval', '$timeout',
    ($scope, $http, $interval, $timeout) ->
      $scope.mode = { id: 0, name: "Main" }
      $scope.CONTROL_MODES = [ 
        { id: 0, name: "Main" },
        { id: 1, name: "Aux1" },
        { id: 2, name: "Aux2" },
        { id: 3, name: "Aux3" },
        { id: 4, name: "Aux4" },
        { id: 5, name: "Aux5" },
        { id: 6, name: "Aux6" }
      ]

      defaultSuccess = (data) ->
        # console.log(data)

      $scope.changeMode = () ->
        console.log($scope.mode)

      findChannel = (device, input) ->
        for channel in $scope.channels
          return channel if channel.device == device && channel.input == input

      findChainChannel = (device, targetDevice) ->
        for channel in $scope.channels
          return channel if channel.device == device && channel.chainDevice == targetDevice

      getParentProgramChannel = ->
        findChannel(0, $scope.state[0].video.programInput)

      getVirtualProgramChannel = ->
        parentProgramChannel = findChannel(0, $scope.state[0].video.programInput)
        if parentProgramChannel? && parentProgramChannel.chainDevice?
          findChannel(parentProgramChannel.chainDevice, $scope.state[parentProgramChannel.chainDevice].video.programInput)
        else
          findChannel(0, $scope.state[0].video.programInput)

      getVirtualPreviewChannel = ->
        parentProgramChannel = findChannel(0, $scope.state[0].video.programInput)
        parentPreviewChannel = findChannel(0, $scope.state[0].video.previewInput)
        if parentPreviewChannel? && parentPreviewChannel.chainDevice? && parentProgramChannel.chainDevice == parentPreviewChannel.chainDevice
          findChannel(parentPreviewChannel.chainDevice, $scope.state[parentPreviewChannel.chainDevice].video.previewInput)
        else if parentPreviewChannel? && parentPreviewChannel.chainDevice?
          findChannel(parentPreviewChannel.chainDevice, $scope.state[parentPreviewChannel.chainDevice].video.programInput)
        else
          findChannel(0, $scope.state[0].video.previewInput)

      getTransitionDevice = ->
        parentProgramChannel = findChannel(0, $scope.state[0].video.programInput)
        parentPreviewChannel = findChannel(0, $scope.state[0].video.previewInput)
        console.log parentProgramChannel, parentPreviewChannel
        if parentPreviewChannel.chainDevice? && parentProgramChannel.chainDevice == parentPreviewChannel.chainDevice
          parentPreviewChannel.chainDevice
        else
          0

      $scope.isProgramChannel = (channel) ->
        programChannel = getVirtualProgramChannel()
        return if !programChannel
        programChannel.device == channel.device && programChannel.input == channel.input

      $scope.isPreviewChannel = (channel) ->
        previewChannel = getVirtualPreviewChannel()
        return if !previewChannel
        previewChannel.device == channel.device && previewChannel.input == channel.input

      $scope.getChannelInput = (channel) ->
        $scope.state[channel.device].channels[channel.input]

      changePreviewInput = (device, input) ->
        if $scope.mode.id == 0
          $http.post('/api/changePreviewInput', device: device, input: input).success(defaultSuccess)
        else 
          $http.post('/api/changeAuxInput', device: device, aux: $scope.mode, input: input).success(defaultSuccess)

      changeProgramInput = (device, input) ->
        if $scope.mode.id == 0
          $http.post('/api/changeProgramInput', device: device, input: input).success(defaultSuccess)
        else 
          $http.post('/api/changeAuxInput', device: device, aux: $scope.mode, input: input).success(defaultSuccess)

      $scope.changeInput = (channel) ->
        isParentDevice = channel.device == 0
        if isParentDevice
          changePreviewInput(0, channel.input)
        else
          chainChannel = findChainChannel(0, channel.device)
          changePreviewInput(chainChannel.device, chainChannel.input)
          if getParentProgramChannel().chainDevice == channel.device
            changePreviewInput(channel.device, channel.input)
          else
            changeProgramInput(channel.device, channel.input)

      $scope.autoTransition = (device = getTransitionDevice()) ->
        return if $scope.mode.id != 0
        $http.post('/api/autoTransition', device: device).success(defaultSuccess)

      $scope.cutTransition = (device = getTransitionDevice()) ->
        return if $scope.mode.id != 0
        $http.post('/api/cutTransition', device: device).success(defaultSuccess)

      $scope.changeTransitionPosition = (percent, device = getTransitionDevice()) ->
        return if $scope.mode.id != 0
        $http.post('/api/changeTransitionPosition', device: device, position: parseInt(percent*10000)).success(defaultSuccess)

      $scope.changeTransitionType = (type) ->
        return if $scope.mode.id != 0
        $http.post('/api/changeTransitionType', type: type).success(defaultSuccess)

      $scope.toggleUpstreamKeyNextBackground = ->
        return if $scope.mode.id != 0
        state = !$scope.state[0].video.upstreamKeyNextBackground
        $http.post('/api/changeUpstreamKeyNextBackground', device: 0, state: state).success(defaultSuccess)

      $scope.toggleUpstreamKeyNextState = (number) ->
        return if $scope.mode.id != 0
        state = !$scope.state[0].video.upstreamKeyNextState[number]
        $http.post('/api/changeUpstreamKeyNextState', device: 0, number: number, state: state).success(defaultSuccess)

      $scope.toggleUpstreamKeyState = (number) ->
        return if $scope.mode.id != 0
        state = !$scope.state[0].video.upstreamKeyState[number]
        $http.post('/api/changeUpstreamKeyState', device: 0, number: number, state: state).success(defaultSuccess)

      registerSlider((err, percent) ->
        $scope.changeTransitionPosition(percent);
      )

      $scope.refresh = ->
        $http.get('/api/switchersStatePolling').success((data) ->
          $scope.state = data
          $timeout($scope.refresh, 0)
        )
      $timeout($scope.refresh, 0)

      $interval( ->
        $http.get('/api/switchersState').success((data) ->
          $scope.state = data
        )
      , 500)

      $interval( ->
        date    = new Date()
        hours   = ("0" + date.getHours()).slice(-2)
        minutes = ("0" + date.getMinutes()).slice(-2)
        seconds = ("0" + date.getSeconds()).slice(-2)
        $scope.time = "#{hours}:#{minutes}:#{seconds}"
      , 1000)

      $http.get('/api/channels').success((data) ->
        $scope.channels = data
      )
  ])
