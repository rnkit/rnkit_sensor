/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import { AppRegistry, Text ,StyleSheet,View,TouchableHighlight} from 'react-native';
import RNKitSensor from "rnkit_sensor";

export default class App extends Component {
    constructor(props){
        super(props);
        RNKitSensor.initial('你好呀',20,5);
        // RNKitSensor.check();
        // RNKitSensor.save("11111","222222",9);
        // RNKitSensor.save("11111","222222",9);
        console.log('哈哈哈哈========');
        this.state = {
            count: -3
        }
    }



    async _nextPage() {

        try {
            var count = await RNKitSensor.getFailCount();
            console.log('返回值是:====' + count);
        } catch (e) {
            console.log('错误是:====' + e);
        }
    }
  render() {

    return (

        <View style={styles.constainer}>

            <TouchableHighlight
                style={styles.touch}
                onPress={this._nextPage.bind(this)}>
                <View>
                    <Text>下一个页面</Text>
                </View>
            </TouchableHighlight>
        </View>

    )

   }
}


const styles = StyleSheet.create({
    constainer: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
    },
    touch: {
        marginTop: 20,
        width: 100,
        height: 40,
        backgroundColor: 'green'
    },

});