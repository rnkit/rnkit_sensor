/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import { AppRegistry, Text } from 'react-native';
import RNKitSensor from "rnkit_sensor";

export default class App extends Component {

  
  render() {
    // RNKitSensor.save("11111","222222");
    RNKitSensor.check();
    return (
        <Text>'666666666677'</Text>
    )

   }
}
