# Opifex.Nova.coffee
#
#	© 2013 Dave Goehrig <dave@dloh.org>
#

cloud = require 'pkgcloud'
config = require "#{process.env.HOME}/.nova.coffee"

Nova = () ->
	self = this
	self.client = cloud.providers.rackspace.compute.createClient { username: config.username, apiKey: config.api.key }
	self["list.flavors"] = () ->
		self.client.getFlavors (error, flavors) ->
			if error
				console.log "Failed to fetch flavors #{error}"
				return self.send [ 'nova', 'error', error ]
			self.flavors = flavors.map (x) ->
				id: x.id
				name: x.name
				ram: x.ram
				vcpus: x.vcpus
				disk: x.disk
				swap: x.swap
			self.send  [ 'nova', 'list.flavors', self.flavors ]
	self["list.images"] = () ->
		self.client.getImages (error, images) ->
			if error
				console.log "Failed to fetch images #{error}"
				return self.send [ 'nova', 'error', error ]
			self.images = images.map (x) ->
				id: x.id
				name: x.name
				created: x.created
				updated: x.updated
				status: x.status
				progress: x.progress
			self.send  [ 'nova', 'list.images', self.images ]
	self["list.servers"] = () ->
		self.client.getServers (error, servers) ->
			if error
				console.log "Failed to fetch servers #{error}"
				return self.send [ 'nova', 'error', error ]
			self.servers = servers.map (x) ->
				id: x.id
				name: x.name
				status: x.status
				progress: x.progress
				image: x.imageId
				flavor: x.flavorId
				host: x.hostId
				public:  (x.addresses.public.filter (y) -> y.version == 4)[0].addr
				private:  (x.addresses.private.filter (y) -> y.version == 4)[0].addr
			self.send [ 'nova', 'list.servers', self.servers ]
	self["create.server"] = (name,image,flavor) ->
		self.client.createServer {
			name: name,
			image: image,
			flavor: flavor,
			}, (error, server) ->
				if error
					console.log "Failed to create server #{error}"
					return self.send [ 'nova', 'error', error ]
				console.log(server)
				self.send ['nova', "create.server", server.name, server.id, server.adminPass ]
				self.servers.push server
	self["snapshot.server"] = (name,id) ->
		self.client.createImage { name: name, server: id }, (error, image) ->
			if error
				console.log "Failed to snapshot server #{error}"
				return self.send [ 'nova', 'error', error ]
			console.log(image)
			self.send [ 'nova', 'snapshot.server', image.name, image.id ]
			self.images.push(image)
	self["help"] = () ->
		self.send [ 'nova', 'help', [ 'list.servers'], ['list.flavors'], ['list.images'], ['create.server', 'name','image','flavor'],['snapshot.server','name','image' ] ]
	self["*"] = (message...) ->
		console.log "Unknown message #{ JSON.stringify(message) }"

module.exports = Nova
