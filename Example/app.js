/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableHighlight
} from 'react-native';

import RNKitSensor from 'rnkit_sensor';


// class Button extends Component {
//   render() {
//     return (
//       <TouchableHighlight
//         onPress={() => this.props.onPress()}
//         style={[styles.button, this.props.style]}
//       >
//         <Text style={styles.buttonText}>{this.props.title}</Text>
//       </TouchableHighlight>
//     )
//   }
// }

export default class App extends Component {

  constructor() {
    super();
    this.state = {
      content: {}
    }    
  }

  render() {

    RNKitSensor.initializationDB();

    return (
        <Text>'你好'</Text>
    )

   }
}

